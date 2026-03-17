-- SECURITY DEFINER function bypasses RLS when checking the admin role,
-- breaking the infinite recursion that occurs when a profiles policy
-- queries the profiles table to resolve another profiles policy.
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Drop the recursive policies added in the previous migration
drop policy if exists "admin full access" on public.profiles;
drop policy if exists "admin full access" on public.teams;
drop policy if exists "admin full access" on public.team_members;
drop policy if exists "admin full access" on public.availabilities;
drop policy if exists "admin full access" on public.scrims;
drop policy if exists "admin full access" on public.scrim_teams;

-- Re-create using the SECURITY DEFINER function
create policy "admin full access" on public.profiles       for all using (public.is_admin());
create policy "admin full access" on public.teams          for all using (public.is_admin());
create policy "admin full access" on public.team_members   for all using (public.is_admin());
create policy "admin full access" on public.availabilities for all using (public.is_admin());
create policy "admin full access" on public.scrims         for all using (public.is_admin());
create policy "admin full access" on public.scrim_teams    for all using (public.is_admin());
