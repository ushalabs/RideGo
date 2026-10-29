-- RideGo: Authentication, User Roles, and Operator Management Migration
-- Phase 2: Autonomous Database Architecture

-- Enable UUID extension if not already enabled
create extension if not exists "uuid-ossp";

-- Role and Status Enums
do $$ begin
  create type public.app_user_role as enum ('customer', 'operator', 'admin');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.operator_approval_status as enum ('pending', 'approved', 'rejected');
exception
  when duplicate_object then null;
end $$;

-- 1. PROFILES TABLE
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone_number text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. USER ROLES TABLE (Authoritative Server-Enforced Role Assignments)
create table if not exists public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_user_role not null default 'customer',
  created_at timestamptz not null default now(),
  constraint uq_user_role unique (user_id, role)
);

-- 3. OPERATORS TABLE
create table if not exists public.operators (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  owner_name text not null,
  business_name text not null,
  contact_number text not null,
  business_location text not null,
  approval_status public.operator_approval_status not null default 'pending',
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. OPERATOR APPLICATIONS TABLE (Audit Trail for Business Requests)
create table if not exists public.operator_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_name text not null,
  owner_name text not null,
  contact_number text not null,
  business_location text not null,
  status public.operator_approval_status not null default 'pending',
  notes text,
  created_at timestamptz not null default now()
);

-- Indexes for performance
create index if not exists idx_user_roles_user_id on public.user_roles(user_id);
create index if not exists idx_operators_user_id on public.operators(user_id);
create index if not exists idx_operators_approval_status on public.operators(approval_status);

-- SECURITY DEFINER HELPER FUNCTIONS (Prevent Privilege Escalation)
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.user_roles
    where user_id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.is_approved_operator()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.operators
    where user_id = auth.uid()
      and approval_status = 'approved'
  );
$$;

create or replace function public.get_user_primary_role(p_user_id uuid)
returns text
language plpgsql
security definer
stable
as $$
declare
  v_role text;
begin
  if exists (select 1 from public.user_roles where user_id = p_user_id and role = 'admin') then
    return 'admin';
  elsif exists (select 1 from public.operators where user_id = p_user_id) then
    return 'operator';
  else
    return 'customer';
  end if;
end;
$$;

-- ADMIN BOOTSTRAP FUNCTION (Privileged manual execution only)
create or replace function public.bootstrap_admin(target_user_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.user_roles (user_id, role)
  values (target_user_id, 'admin')
  on conflict (user_id, role) do nothing;
end;
$$;

-- TRIGGER FUNCTION FOR AUTOMATIC PROFILE AND ROLE ASSIGNMENT
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_name text;
begin
  v_name := coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1));
  v_role := coalesce(new.raw_user_meta_data->>'role', 'customer');

  -- Create Profile
  insert into public.profiles (id, full_name)
  values (new.id, v_name)
  on conflict (id) do update
  set full_name = excluded.full_name, updated_at = now();

  -- Assign Customer Role
  insert into public.user_roles (user_id, role)
  values (new.id, 'customer')
  on conflict (user_id, role) do nothing;

  -- If registered as operator, create pending operator record
  if v_role = 'operator' then
    insert into public.operators (
      user_id,
      owner_name,
      business_name,
      contact_number,
      business_location,
      approval_status
    ) values (
      new.id,
      v_name,
      coalesce(new.raw_user_meta_data->>'business_name', v_name || ' Transport'),
      coalesce(new.raw_user_meta_data->>'contact_number', ''),
      coalesce(new.raw_user_meta_data->>'business_location', 'Samar/Leyte'),
      'pending'
    ) on conflict (user_id) do nothing;

    insert into public.operator_applications (
      user_id,
      business_name,
      owner_name,
      contact_number,
      business_location,
      status
    ) values (
      new.id,
      coalesce(new.raw_user_meta_data->>'business_name', v_name || ' Transport'),
      v_name,
      coalesce(new.raw_user_meta_data->>'contact_number', ''),
      coalesce(new.raw_user_meta_data->>'business_location', 'Samar/Leyte'),
      'pending'
    );
  end if;

  return new;
end;
$$;

-- Trigger execution on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ROW LEVEL SECURITY (RLS) POLICIES
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.operators enable row level security;
alter table public.operator_applications enable row level security;

-- Profiles Policies
create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin());

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- User Roles Policies (Admins can view and manage, users can view their own role)
create policy "Users can view their assigned roles"
  on public.user_roles for select
  using (auth.uid() = user_id or public.is_admin());

create policy "Only admins can insert or modify roles"
  on public.user_roles for all
  using (public.is_admin())
  with check (public.is_admin());

-- Operators Policies
create policy "Public can view approved operators"
  on public.operators for select
  using (approval_status = 'approved' or auth.uid() = user_id or public.is_admin());

create policy "Operators can update their business details but not approval status"
  on public.operators for update
  using (auth.uid() = user_id or public.is_admin())
  with check (
    -- Normal operator cannot self-approve
    (auth.uid() = user_id and approval_status = (select approval_status from public.operators where user_id = auth.uid()))
    or public.is_admin()
  );

create policy "Only admins can approve or reject operators"
  on public.operators for update
  using (public.is_admin())
  with check (public.is_admin());

-- Operator Applications Policies
create policy "Users can view their own operator application"
  on public.operator_applications for select
  using (auth.uid() = user_id or public.is_admin());

create policy "Users can create operator application"
  on public.operator_applications for insert
  with check (auth.uid() = user_id);
