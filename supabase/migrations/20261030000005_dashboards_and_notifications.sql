-- RideGo: Notifications, Dashboard Reporting, and Operational Audit Functions
-- Phase 6: Autonomous Database Architecture

-- 1. NOTIFICATIONS TABLE
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null,
  is_read boolean not null default false,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_recipient on public.notifications(recipient_id, is_read);

-- Enable RLS
alter table public.notifications enable row level security;

create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = recipient_id or public.is_admin());

create policy "Users can mark their own notifications as read"
  on public.notifications for update
  using (auth.uid() = recipient_id or public.is_admin())
  with check (auth.uid() = recipient_id or public.is_admin());

-- 2. AUTOMATIC NOTIFICATION TRIGGERS
create or replace function public.notify_booking_status_change()
returns trigger
language plpgsql
security definer
as $$
declare
  v_op_user_id uuid;
begin
  -- Get operator user_id
  select user_id into v_op_user_id
  from public.operators
  where id = new.operator_id;

  -- 1. When a new booking is created -> notify operator and customer
  if tg_op = 'INSERT' then
    if v_op_user_id is not null then
      insert into public.notifications (recipient_id, title, message, type, metadata)
      values (
        v_op_user_id,
        'New Booking Received',
        'New reservation ' || new.booking_reference || ' for ' || new.passenger_count || ' seat(s) on ' || new.pickup_location || ' to ' || new.dropoff_location || '.',
        'booking_created',
        jsonb_build_object('booking_id', new.id, 'reference', new.booking_reference)
      );
    end if;

    insert into public.notifications (recipient_id, title, message, type, metadata)
    values (
      new.customer_id,
      'Booking Reserved',
      'Your booking ' || new.booking_reference || ' has been received. Please pay at terminal counter prior to departure.',
      'booking_created',
      jsonb_build_object('booking_id', new.id, 'reference', new.booking_reference)
    );
  end if;

  -- 2. When booking is updated -> notify customer on status changes
  if tg_op = 'UPDATE' and old.status != new.status then
    if new.status = 'confirmed' then
      insert into public.notifications (recipient_id, title, message, type, metadata)
      values (
        new.customer_id,
        'Booking Confirmed',
        'Your trip ' || new.booking_reference || ' is confirmed! Payment status: ' || new.payment_status || '.',
        'booking_confirmed',
        jsonb_build_object('booking_id', new.id, 'reference', new.booking_reference)
      );
    elsif new.status = 'cancelled' then
      insert into public.notifications (recipient_id, title, message, type, metadata)
      values (
        new.customer_id,
        'Booking Cancelled',
        'Reservation ' || new.booking_reference || ' has been cancelled. ' || coalesce(new.cancellation_reason, ''),
        'booking_cancelled',
        jsonb_build_object('booking_id', new.id, 'reference', new.booking_reference)
      );
    elsif new.status = 'completed' then
      insert into public.notifications (recipient_id, title, message, type, metadata)
      values (
        new.customer_id,
        'Trip Completed',
        'Thank you for traveling with RideGo on route ' || new.pickup_location || ' to ' || new.dropoff_location || '!',
        'booking_completed',
        jsonb_build_object('booking_id', new.id, 'reference', new.booking_reference)
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists on_booking_status_change on public.bookings;
create trigger on_booking_status_change
  after insert or update on public.bookings
  for each row execute function public.notify_booking_status_change();

-- 3. NOTIFY OPERATOR APPROVAL STATUS
create or replace function public.notify_operator_approval()
returns trigger
language plpgsql
security definer
as $$
begin
  if old.approval_status != new.approval_status then
    if new.approval_status = 'approved' then
      insert into public.notifications (recipient_id, title, message, type)
      values (
        new.user_id,
        'Operator Account Approved!',
        'Welcome to RideGo! Your transport business ' || new.business_name || ' is approved to register vehicles and publish schedules.',
        'operator_approved'
      );
    elsif new.approval_status = 'rejected' then
      insert into public.notifications (recipient_id, title, message, type)
      values (
        new.user_id,
        'Operator Application Update',
        'Your application was reviewed and could not be approved at this time: ' || coalesce(new.rejection_reason, 'Verification incomplete.'),
        'operator_rejected'
      );
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists on_operator_approval on public.operators;
create trigger on_operator_approval
  after update on public.operators
  for each row execute function public.notify_operator_approval();

-- 4. DATABASE METRICS RPC (Genuine Reporting for Admin Dashboard)
create or replace function public.get_admin_dashboard_metrics()
returns jsonb
language plpgsql
security definer
stable
as $$
declare
  v_customers int;
  v_operators int;
  v_pending_ops int;
  v_approved_ops int;
  v_vehicles int;
  v_schedules int;
  v_total_bookings int;
  v_completed_bookings int;
  v_cancelled_bookings int;
  v_booked_value numeric(12,2);
  v_collected_cash numeric(12,2);
begin
  select count(*) into v_customers from public.profiles;
  select count(*) into v_operators from public.operators;
  select count(*) into v_pending_ops from public.operators where approval_status = 'pending';
  select count(*) into v_approved_ops from public.operators where approval_status = 'approved';
  select count(*) into v_vehicles from public.vehicles where status = 'active';
  select count(*) into v_schedules from public.schedules where status = 'scheduled';
  
  select count(*) into v_total_bookings from public.bookings;
  select count(*) into v_completed_bookings from public.bookings where status = 'completed';
  select count(*) into v_cancelled_bookings from public.bookings where status = 'cancelled';
  
  -- Total booked volume across all reservations
  select coalesce(sum(total_fare), 0.00) into v_booked_value from public.bookings where status != 'cancelled';
  
  -- Actual collected cash verified at terminal
  select coalesce(sum(total_fare), 0.00) into v_collected_cash from public.bookings where payment_status = 'paid';

  return jsonb_build_object(
    'total_customers', v_customers,
    'total_operators', v_operators,
    'pending_operator_approvals', v_pending_ops,
    'approved_operators', v_approved_ops,
    'registered_vehicles', v_vehicles,
    'active_schedules', v_schedules,
    'total_bookings', v_total_bookings,
    'completed_bookings', v_completed_bookings,
    'cancelled_bookings', v_cancelled_bookings,
    'total_booked_value', v_booked_value,
    'actual_collected_cash', v_collected_cash
  );
end;
$$;
