-- Allow team members to edit each other's availability calendars.
--
-- Adds is_teammate_of() — a comprehensive SECURITY DEFINER function covering
-- all three relationship cases:
--   1. Both users are active members of the same team (team_members ↔ team_members)
--   2. Current user is the team leader, target is an active member
--   3. Current user is an active member, target is the team leader
--
-- The existing shares_team_with() only checks team_members ↔ team_members and
-- misses cases where the leader is stored in teams.leader_id (not team_members).

create or replace function public.is_teammate_of(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    -- Both are active members of the same team
    select 1 from public.team_members tm1
    join public.team_members tm2 on tm1.team_id = tm2.team_id
    where tm1.user_id = auth.uid() and tm2.user_id = p_user_id
      and tm1.status = 'active' and tm2.status = 'active'
  ) or exists (
    -- Current user is team leader, target is an active member of that team
    select 1 from public.teams t
    join public.team_members tm on tm.team_id = t.id
    where t.leader_id = auth.uid() and tm.user_id = p_user_id
      and tm.status = 'active'
  ) or exists (
    -- Current user is an active member, target is the team leader
    select 1 from public.teams t
    join public.team_members tm on tm.team_id = t.id
    where tm.user_id = auth.uid() and t.leader_id = p_user_id
      and tm.status = 'active'
  );
$$;

-- RLS policy: team members can INSERT / UPDATE / DELETE each other's availabilities.
-- The existing "own availability" policy still covers the owner; this adds teammates.
create policy "Teammates can edit each other's availability"
  on public.availabilities
  for all
  using  (public.is_teammate_of(user_id))
  with check (public.is_teammate_of(user_id));
