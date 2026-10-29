-- RideGo: Vehicles, Corridors, Locations, Route Stops, and Schedules Migration
-- Phase 3: Autonomous Database Architecture

-- 1. ENUMS
do $$ begin
  create type public.vehicle_category as enum ('van', 'bus', 'car', 'motorcycle');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.vehicle_status as enum ('active', 'maintenance', 'inactive', 'retired');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.schedule_status as enum ('scheduled', 'boarding', 'in_transit', 'completed', 'cancelled');
exception
  when duplicate_object then null;
end $$;

-- 2. VEHICLES TABLE
create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  operator_id uuid not null references public.operators(id) on delete cascade,
  name text not null,
  category public.vehicle_category not null default 'van',
  plate_number text not null,
  passenger_capacity int not null check (passenger_capacity > 0),
  description text,
  image_url text,
  status public.vehicle_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_vehicle_plate unique (plate_number)
);

-- 3. VEHICLE IMAGES TABLE (Storage attachments)
create table if not exists public.vehicle_images (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  image_url text not null,
  caption text,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

-- 4. CORRIDORS TABLE (Service areas)
create table if not exists public.corridors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique not null,
  description text,
  created_at timestamptz not null default now()
);

-- 5. LOCATIONS TABLE (Samar & Leyte Hubs & Stops)
create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  province text not null,
  terminal_name text,
  created_at timestamptz not null default now()
);

-- 6. ROUTE VARIANTS TABLE
create table if not exists public.route_variants (
  id uuid primary key default gen_random_uuid(),
  corridor_id uuid not null references public.corridors(id) on delete cascade,
  name text not null,
  origin_id uuid not null references public.locations(id),
  destination_id uuid not null references public.locations(id),
  estimated_minutes int not null default 120,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 7. ROUTE STOPS TABLE (Ordered sequence of passenger stops)
create table if not exists public.route_stops (
  id uuid primary key default gen_random_uuid(),
  route_variant_id uuid not null references public.route_variants(id) on delete cascade,
  location_id uuid not null references public.locations(id),
  stop_order int not null check (stop_order >= 0),
  allow_pickup boolean not null default true,
  allow_dropoff boolean not null default true,
  estimated_minutes_from_origin int not null default 0,
  constraint uq_route_stop_order unique (route_variant_id, stop_order)
);

-- 8. VEHICLE ROUTES TABLE (Operator Vehicle - Route Assignment)
create table if not exists public.vehicle_routes (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  route_variant_id uuid not null references public.route_variants(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint uq_vehicle_route unique (vehicle_id, route_variant_id)
);

-- 9. SCHEDULES TABLE (Operator Departures)
create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  operator_id uuid not null references public.operators(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id),
  route_variant_id uuid not null references public.route_variants(id),
  departure_time timestamptz not null,
  expected_arrival_time timestamptz,
  available_capacity int not null,
  total_capacity int not null,
  status public.schedule_status not null default 'scheduled',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_capacity check (available_capacity >= 0 and available_capacity <= total_capacity)
);

-- Indexes for fast queries
create index if not exists idx_vehicles_operator on public.vehicles(operator_id);
create index if not exists idx_vehicles_category on public.vehicles(category);
create index if not exists idx_route_stops_variant on public.route_stops(route_variant_id, stop_order);
create index if not exists idx_schedules_departure on public.schedules(departure_time);
create index if not exists idx_schedules_route on public.schedules(route_variant_id);

-- RLS ENABLEMENT
alter table public.vehicles enable row level security;
alter table public.vehicle_images enable row level security;
alter table public.corridors enable row level security;
alter table public.locations enable row level security;
alter table public.route_variants enable row level security;
alter table public.route_stops enable row level security;
alter table public.vehicle_routes enable row level security;
alter table public.schedules enable row level security;

-- RLS POLICIES
-- Vehicles: public can view active vehicles, approved operators can manage their own
create policy "Anyone can view active vehicles"
  on public.vehicles for select
  using (status = 'active' or auth.uid() in (select user_id from public.operators where id = operator_id) or public.is_admin());

create policy "Operators can insert their own vehicles"
  on public.vehicles for insert
  with check (
    auth.uid() in (select user_id from public.operators where id = operator_id and approval_status = 'approved')
    or public.is_admin()
  );

create policy "Operators can update their own vehicles"
  on public.vehicles for update
  using (auth.uid() in (select user_id from public.operators where id = operator_id) or public.is_admin());

create policy "Operators can delete their own vehicles"
  on public.vehicles for delete
  using (auth.uid() in (select user_id from public.operators where id = operator_id) or public.is_admin());

-- Corridors, Locations, Routes: Readable by everyone, writable only by Admins
create policy "Anyone can view corridors" on public.corridors for select using (true);
create policy "Admins can manage corridors" on public.corridors for all using (public.is_admin());

create policy "Anyone can view locations" on public.locations for select using (true);
create policy "Admins can manage locations" on public.locations for all using (public.is_admin());

create policy "Anyone can view route variants" on public.route_variants for select using (is_active = true or public.is_admin());
create policy "Admins can manage route variants" on public.route_variants for all using (public.is_admin());

create policy "Anyone can view route stops" on public.route_stops for select using (true);
create policy "Admins can manage route stops" on public.route_stops for all using (public.is_admin());

-- Schedules: Anyone can view scheduled trips, operators manage their own
create policy "Anyone can view scheduled departures"
  on public.schedules for select
  using (true);

create policy "Operators can manage their departures"
  on public.schedules for all
  using (auth.uid() in (select user_id from public.operators where id = operator_id) or public.is_admin())
  with check (auth.uid() in (select user_id from public.operators where id = operator_id) or public.is_admin());

-- SEED DATA: SAMAR & LEYTE CORRIDORS AND LOCATIONS
insert into public.corridors (id, name, code, description) values
  ('11111111-1111-1111-1111-111111111101', 'Southbound — Catbalogan to Tacloban', 'SB_CAT_TAC', 'Main transit artery connecting Western Samar to Leyte via San Juanico Bridge'),
  ('11111111-1111-1111-1111-111111111102', 'Northbound — Catbalogan to Calbayog', 'NB_CAT_CAL', 'Coastal and highland Samar highway corridor')
on conflict (code) do nothing;

-- Insert Locations
insert into public.locations (name, province, terminal_name) values
  ('Catbalogan City', 'Samar', 'Catbalogan Grand Central Terminal'),
  ('Paranas (Wright)', 'Samar', 'Paranas Junction Bus Stop'),
  ('Motiong', 'Samar', 'Motiong Poblacion Stop'),
  ('Jiabong', 'Samar', 'Jiabong Highway Terminal'),
  ('San Jorge', 'Samar', 'San Jorge Crossing'),
  ('Gandara', 'Samar', 'Gandara Public Market Station'),
  ('Pagsanghan', 'Samar', 'Pagsanghan Junction'),
  ('Tarangnan', 'Samar', 'Tarangnan Diversion Stop'),
  ('Santa Margarita', 'Samar', 'Santa Margarita Transit Stop'),
  ('Calbayog City', 'Samar', 'Calbayog Central Bus Terminal'),
  ('Villareal', 'Samar', 'Villareal Junction Station'),
  ('Pinabacdao', 'Samar', 'Pinabacdao Poblacion Stop'),
  ('Calbiga', 'Samar', 'Calbiga Central Stop'),
  ('Basey', 'Samar', 'Basey Municipal Bus Terminal'),
  ('Marabut', 'Samar', 'Marabut Coastal Stop'),
  ('Santa Rita', 'Samar', 'Santa Rita Junction'),
  ('San Juanico Bridge', 'Samar/Leyte', 'San Juanico Viewpoint Station'),
  ('Tacloban City', 'Leyte', 'Tacloban New Bus Terminal (Abucay)')
on conflict (name) do nothing;
