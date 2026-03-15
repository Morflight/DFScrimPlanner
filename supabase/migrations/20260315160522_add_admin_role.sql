-- Add 'admin' as a valid role (admin > leader > player/filler)
alter table public.profiles
  drop constraint profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('admin', 'leader', 'player', 'filler'));

-- Admins bypass RLS — they can read and manage everything
create policy "admin full access"
  on public.profiles for all
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "admin full access"
  on public.teams for all
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "admin full access"
  on public.team_members for all
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "admin full access"
  on public.availabilities for all
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "admin full access"
  on public.scrims for all
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "admin full access"
  on public.scrim_teams for all
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );
