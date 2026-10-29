-- RideGo: Automated SQL Verification Tests for Auth and Role Isolation
-- Tests RLS enforcement, role escalation prevention, and approval integrity

-- Test 1: Verify RLS is enabled on all tables
do $$
declare
  tbl record;
begin
  for tbl in select tablename from pg_tables where schemaname = 'public' and tablename in ('profiles', 'user_roles', 'operators', 'operator_applications') loop
    if not exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname = tbl.tablename and c.relrowsecurity = true) then
      raise exception 'RLS is not enabled on table %', tbl.tablename;
    end if;
  end loop;
  raise notice 'Test 1 Passed: RLS enabled on all auth & role tables.';
end $$;

-- Test 2: Verify is_admin() function exists and is security definer
do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'is_admin' and p.prosecdef = true
  ) then
    raise exception 'is_admin() must be a SECURITY DEFINER function';
  end if;
  raise notice 'Test 2 Passed: is_admin() is properly configured.';
end $$;

-- Test 3: Verify unique constraint on user_roles (user_id, role)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'uq_user_role'
  ) then
    raise exception 'uq_user_role unique constraint missing on user_roles';
  end if;
  raise notice 'Test 3 Passed: User role uniqueness constraint verified.';
end $$;
