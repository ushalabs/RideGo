-- RideGo: Real-Time Booking Engine, Transactional Capacity Control, and Audit Logging
-- Phase 5: Autonomous Database Architecture

-- 1. ENUMS
do $$ begin
  create type public.booking_status as enum ('pending', 'confirmed', 'cancelled', 'completed');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.payment_status as enum ('pending', 'paid', 'cancelled', 'refunded');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.payment_method as enum ('cash_terminal');
exception
  when duplicate_object then null;
end $$;

-- 2. BOOKINGS TABLE
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_reference text unique not null,
  idempotency_key text unique not null,
  customer_id uuid not null references auth.users(id) on delete cascade,
  schedule_id uuid not null references public.schedules(id) on delete restrict,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  operator_id uuid not null references public.operators(id) on delete restrict,
  pickup_location text not null,
  dropoff_location text not null,
  travel_date date not null,
  departure_time timestamptz not null,
  passenger_count int not null check (passenger_count > 0),
  base_fare numeric(10,2) not null,
  segment_charge numeric(10,2) not null default 0.00,
  terminal_fee numeric(10,2) not null default 10.00,
  total_fare numeric(10,2) not null check (total_fare >= 0),
  status public.booking_status not null default 'pending',
  payment_method public.payment_method not null default 'cash_terminal',
  payment_status public.payment_status not null default 'pending',
  payment_confirmed_at timestamptz,
  payment_confirmed_by uuid references auth.users(id),
  cancellation_reason text,
  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. BOOKING EVENTS TABLE (Immutable Audit Trail)
create table if not exists public.booking_events (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  actor_id uuid references auth.users(id),
  event_type text not null,
  previous_status text,
  new_status text,
  metadata jsonb,
  created_at timestamptz not null default now()
);

-- Indexes for lightning-fast queries and concurrency
create index if not exists idx_bookings_customer on public.bookings(customer_id, status);
create index if not exists idx_bookings_operator on public.bookings(operator_id, status);
create index if not exists idx_bookings_schedule on public.bookings(schedule_id);
create index if not exists idx_bookings_reference on public.bookings(booking_reference);
create index if not exists idx_booking_events_booking on public.booking_events(booking_id);

-- Enable RLS
alter table public.bookings enable row level security;
alter table public.booking_events enable row level security;

-- 4. RLS POLICIES FOR BOOKINGS
create policy "Customers can view their own bookings"
  on public.bookings for select
  using (
    auth.uid() = customer_id
    or auth.uid() in (select user_id from public.operators where id = operator_id)
    or public.is_admin()
  );

create policy "Customers can insert their own bookings via function"
  on public.bookings for insert
  with check (auth.uid() = customer_id or public.is_admin());

create policy "Only authorized actors can update bookings"
  on public.bookings for update
  using (
    auth.uid() = customer_id
    or auth.uid() in (select user_id from public.operators where id = operator_id)
    or public.is_admin()
  );

-- Booking events: visible to stakeholders
create policy "Stakeholders can view booking audit events"
  on public.booking_events for select
  using (
    public.is_admin()
    or auth.uid() in (select customer_id from public.bookings where id = booking_id)
    or auth.uid() in (select op.user_id from public.bookings b join public.operators op on op.id = b.operator_id where b.id = booking_id)
  );

-- 5. TRANSACTIONAL BOOKING CREATION WITH CAPACITY LOCKING
create or replace function public.create_booking_atomic(
  p_idempotency_key text,
  p_customer_id uuid,
  p_schedule_id uuid,
  p_pickup_location text,
  p_dropoff_location text,
  p_passenger_count int,
  p_quoted_fare numeric
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_schedule record;
  v_existing_booking record;
  v_ref text;
  v_new_booking public.bookings%rowtype;
begin
  -- Idempotency check: Return existing booking if already processed
  select * into v_existing_booking
  from public.bookings
  where idempotency_key = p_idempotency_key;

  if found then
    return jsonb_build_object(
      'success', true,
      'is_duplicate', true,
      'booking_id', v_existing_booking.id,
      'booking_reference', v_existing_booking.booking_reference,
      'status', v_existing_booking.status,
      'total_fare', v_existing_booking.total_fare
    );
  end if;

  -- Pessimistic Lock on Schedule row (Prevents Race Conditions and Overbooking)
  select * into v_schedule
  from public.schedules
  where id = p_schedule_id
  for update;

  if not found then
    return jsonb_build_object('success', false, 'error', 'Scheduled departure not found.');
  end if;

  if v_schedule.status != 'scheduled' then
    return jsonb_build_object('success', false, 'error', 'This departure is no longer bookable.');
  end if;

  if v_schedule.available_capacity < p_passenger_count then
    return jsonb_build_object(
      'success', false,
      'error', 'Insufficient capacity. Only ' || v_schedule.available_capacity || ' seat(s) remain.'
    );
  end if;

  -- Generate Unique Human-Readable Reference: RG-YYYY-XXXX
  v_ref := 'RG-' || to_char(now(), 'YYYY') || '-' || lpad(floor(random() * 9000 + 1000)::text, 4, '0');

  -- Deduct seat capacity atomically
  update public.schedules
  set available_capacity = available_capacity - p_passenger_count,
      updated_at = now()
  where id = p_schedule_id;

  -- Create authoritative booking record
  insert into public.bookings (
    booking_reference,
    idempotency_key,
    customer_id,
    schedule_id,
    vehicle_id,
    operator_id,
    pickup_location,
    dropoff_location,
    travel_date,
    departure_time,
    passenger_count,
    base_fare,
    segment_charge,
    terminal_fee,
    total_fare,
    status,
    payment_method,
    payment_status
  ) values (
    v_ref,
    p_idempotency_key,
    p_customer_id,
    p_schedule_id,
    v_schedule.vehicle_id,
    v_schedule.operator_id,
    p_pickup_location,
    p_dropoff_location,
    v_schedule.departure_time::date,
    v_schedule.departure_time,
    p_passenger_count,
    coalesce(v_schedule.fare, 150.00),
    0.00,
    10.00,
    p_quoted_fare,
    'pending',
    'cash_terminal',
    'pending'
  ) returning * into v_new_booking;

  -- Record Audit Trail
  insert into public.booking_events (
    booking_id,
    actor_id,
    event_type,
    previous_status,
    new_status,
    metadata
  ) values (
    v_new_booking.id,
    p_customer_id,
    'created',
    null,
    'pending',
    jsonb_build_object('passengers', p_passenger_count, 'fare', p_quoted_fare)
  );

  return jsonb_build_object(
    'success', true,
    'is_duplicate', false,
    'booking_id', v_new_booking.id,
    'booking_reference', v_new_booking.booking_reference,
    'status', v_new_booking.status,
    'total_fare', v_new_booking.total_fare,
    'remaining_capacity', v_schedule.available_capacity - p_passenger_count
  );
end;
$$;

-- 6. TRANSACTIONAL CANCELLATION WITH AUTOMATIC CAPACITY RESTORATION
create or replace function public.cancel_booking_atomic(
  p_booking_id uuid,
  p_actor_id uuid,
  p_reason text default 'Customer requested cancellation'
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_booking public.bookings%rowtype;
  v_schedule public.schedules%rowtype;
begin
  select * into v_booking
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then
    return jsonb_build_object('success', false, 'error', 'Booking not found');
  end if;

  if v_booking.status = 'cancelled' then
    return jsonb_build_object('success', false, 'error', 'Booking is already cancelled.');
  end if;

  if v_booking.status = 'completed' then
    return jsonb_build_object('success', false, 'error', 'Completed trips cannot be cancelled.');
  end if;

  -- Restore seat capacity onto the schedule
  select * into v_schedule
  from public.schedules
  where id = v_booking.schedule_id
  for update;

  if found then
    update public.schedules
    set available_capacity = least(total_capacity, available_capacity + v_booking.passenger_count),
        updated_at = now()
    where id = v_booking.schedule_id;
  end if;

  -- Update booking status
  update public.bookings
  set status = 'cancelled',
      payment_status = 'cancelled',
      cancellation_reason = p_reason,
      cancelled_at = now(),
      cancelled_by = p_actor_id,
      updated_at = now()
  where id = p_booking_id;

  -- Audit log
  insert into public.booking_events (
    booking_id,
    actor_id,
    event_type,
    previous_status,
    new_status,
    metadata
  ) values (
    p_booking_id,
    p_actor_id,
    'cancelled',
    v_booking.status::text,
    'cancelled',
    jsonb_build_object('reason', p_reason, 'restored_seats', v_booking.passenger_count)
  );

  return jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'cancelled'
  );
end;
$$;

-- 7. CASH PAYMENT CONFIRMATION (Authorized Operators and Admins Only)
create or replace function public.confirm_cash_payment_atomic(
  p_booking_id uuid,
  p_staff_user_id uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_booking public.bookings%rowtype;
  v_is_authorized boolean := false;
begin
  select * into v_booking
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then
    return jsonb_build_object('success', false, 'error', 'Booking not found');
  end if;

  -- Verify staff is admin or belongs to operator
  if exists (select 1 from public.user_roles where user_id = p_staff_user_id and role = 'admin') then
    v_is_authorized := true;
  elsif exists (select 1 from public.operators where id = v_booking.operator_id and user_id = p_staff_user_id) then
    v_is_authorized := true;
  end if;

  if not v_is_authorized then
    return jsonb_build_object('success', false, 'error', 'Unauthorized. Only operators or admins can confirm payment receipts.');
  end if;

  update public.bookings
  set status = 'confirmed',
      payment_status = 'paid',
      payment_confirmed_at = now(),
      payment_confirmed_by = p_staff_user_id,
      updated_at = now()
  where id = p_booking_id;

  insert into public.booking_events (
    booking_id,
    actor_id,
    event_type,
    previous_status,
    new_status,
    metadata
  ) values (
    p_booking_id,
    p_staff_user_id,
    'payment_recorded',
    v_booking.status::text,
    'confirmed',
    jsonb_build_object('amount', v_booking.total_fare, 'method', 'cash_terminal')
  );

  return jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'confirmed',
    'payment_status', 'paid'
  );
end;
$$;
