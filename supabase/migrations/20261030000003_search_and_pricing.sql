-- RideGo: Automatic Pricing Engine & Search Optimization Migration
-- Phase 4: Autonomous Database Architecture

-- 1. FARE RULES TABLE (Administrator Configured)
create table if not exists public.fare_rules (
  id uuid primary key default gen_random_uuid(),
  corridor_id uuid references public.corridors(id) on delete cascade,
  route_variant_id uuid references public.route_variants(id) on delete set null,
  origin_id uuid references public.locations(id) on delete cascade,
  destination_id uuid references public.locations(id) on delete cascade,
  category public.vehicle_category not null default 'van',
  base_fare numeric(10,2) not null check (base_fare >= 0),
  segment_charge numeric(10,2) not null default 0.00 check (segment_charge >= 0),
  terminal_fee numeric(10,2) not null default 10.00 check (terminal_fee >= 0),
  is_active boolean not null default true,
  effective_from timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_fare_rules_lookup on public.fare_rules(origin_id, destination_id, category, is_active);

-- Enable RLS on fare_rules
alter table public.fare_rules enable row level security;
create policy "Anyone can read active fare rules" on public.fare_rules for select using (is_active = true or public.is_admin());
create policy "Admins can manage fare rules" on public.fare_rules for all using (public.is_admin());

-- 2. AUTHORITATIVE FARE CALCULATION FUNCTION (Server-Enforced)
create or replace function public.calculate_authoritative_fare(
  p_route_variant_id uuid,
  p_origin_id uuid,
  p_destination_id uuid,
  p_category public.vehicle_category,
  p_passengers int default 1,
  p_is_private boolean default false
)
returns jsonb
language plpgsql
security definer
stable
as $$
declare
  v_origin_order int;
  v_dest_order int;
  v_base_fare numeric(10,2) := 150.00;
  v_segment_charge numeric(10,2) := 0.00;
  v_terminal_fee numeric(10,2) := 10.00;
  v_total numeric(10,2);
  v_rule record;
begin
  -- Validate stop order on route variant
  select stop_order into v_origin_order
  from public.route_stops
  where route_variant_id = p_route_variant_id and location_id = p_origin_id;

  select stop_order into v_dest_order
  from public.route_stops
  where route_variant_id = p_route_variant_id and location_id = p_destination_id;

  if v_origin_order is not null and v_dest_order is not null then
    if v_origin_order >= v_dest_order then
      return jsonb_build_object(
        'is_valid', false,
        'error', 'Invalid direction: pickup must precede drop-off along the selected route variant.'
      );
    end if;
  end if;

  -- Look up matching active fare rule
  select * into v_rule
  from public.fare_rules
  where origin_id = p_origin_id
    and destination_id = p_destination_id
    and category = p_category
    and is_active = true
  order by effective_from desc
  limit 1;

  if found then
    v_base_fare := v_rule.base_fare;
    v_segment_charge := v_rule.segment_charge;
    v_terminal_fee := v_rule.terminal_fee;
  else
    -- Fallback default by category
    if p_category = 'bus' then
      v_base_fare := 200.00;
    elsif p_category = 'van' then
      v_base_fare := 150.00;
    elsif p_category = 'motorcycle' then
      v_base_fare := 80.00;
    elsif p_category = 'car' then
      v_base_fare := 350.00;
    end if;
  end if;

  if p_is_private then
    -- Private travel formula: total = base_fare + segment_charge + applicable_fees
    v_total := v_base_fare + v_segment_charge + v_terminal_fee;
  else
    -- Shared travel formula: total = (base_fare + segment_charge) * passengers + terminal_fee
    v_total := ((v_base_fare + v_segment_charge) * p_passengers) + v_terminal_fee;
  end if;

  return jsonb_build_object(
    'is_valid', true,
    'base_fare', v_base_fare,
    'segment_charge', v_segment_charge,
    'terminal_fee', v_terminal_fee,
    'passengers', p_passengers,
    'is_private', p_is_private,
    'total_fare', v_total,
    'currency', 'PHP'
  );
end;
$$;

-- 3. SEARCH AVAILABLE TRIPS FUNCTION
create or replace function public.search_available_trips(
  p_origin_name text,
  p_destination_name text,
  p_travel_date date default null,
  p_category text default null,
  p_min_capacity int default 1
)
returns table (
  schedule_id uuid,
  vehicle_id uuid,
  vehicle_name text,
  vehicle_category text,
  plate_number text,
  operator_id uuid,
  operator_name text,
  route_name text,
  origin_name text,
  destination_name text,
  departure_time timestamptz,
  available_capacity int,
  total_capacity int,
  calculated_fare numeric
)
language plpgsql
security definer
stable
as $$
begin
  return query
  select
    s.id as schedule_id,
    v.id as vehicle_id,
    v.name as vehicle_name,
    v.category::text as vehicle_category,
    v.plate_number,
    op.id as operator_id,
    op.business_name as operator_name,
    rv.name as route_name,
    p_origin_name as origin_name,
    p_destination_name as destination_name,
    s.departure_time,
    s.available_capacity,
    s.total_capacity,
    coalesce(fr.base_fare, 150.00) as calculated_fare
  from public.schedules s
  join public.vehicles v on v.id = s.vehicle_id
  join public.operators op on op.id = s.operator_id
  join public.route_variants rv on rv.id = s.route_variant_id
  left join public.fare_rules fr on fr.category = v.category and fr.is_active = true
  where s.status = 'scheduled'
    and s.available_capacity >= p_min_capacity
    and (p_category is null or v.category::text = p_category)
    and (p_travel_date is null or s.departure_time::date = p_travel_date)
  order by s.departure_time asc;
end;
$$;

-- SEED DEMONSTRATION FARE RULES
insert into public.fare_rules (origin_id, destination_id, category, base_fare, segment_charge, terminal_fee, is_active)
select
  orig.id,
  dest.id,
  'van'::public.vehicle_category,
  150.00,
  0.00,
  10.00,
  true
from public.locations orig, public.locations dest
where orig.name = 'Catbalogan City' and dest.name = 'Tacloban City'
on conflict do nothing;

insert into public.fare_rules (origin_id, destination_id, category, base_fare, segment_charge, terminal_fee, is_active)
select
  orig.id,
  dest.id,
  'bus'::public.vehicle_category,
  200.00,
  0.00,
  10.00,
  true
from public.locations orig, public.locations dest
where orig.name = 'Catbalogan City' and dest.name = 'Tacloban City'
on conflict do nothing;

insert into public.fare_rules (origin_id, destination_id, category, base_fare, segment_charge, terminal_fee, is_active)
select
  orig.id,
  dest.id,
  'van'::public.vehicle_category,
  140.00,
  0.00,
  10.00,
  true
from public.locations orig, public.locations dest
where orig.name = 'Catbalogan City' and dest.name = 'Calbayog City'
on conflict do nothing;
