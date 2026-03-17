-- Fix: team leaders stored in teams.leader_id (not team_members) were invisible
-- to is_team_member_of() and participates_in_scrim(), which only checked
-- team_members rows. Leaders couldn't see scrims they didn't organise, and
-- scrim_teams rows for their own team were hidden.

-- ── is_team_member_of ───────────────────────────────────────────────────────
-- Now also returns true when the caller IS the team leader.
create or replace function public.is_team_member_of(p_team_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.team_members
    where team_id = p_team_id and user_id = auth.uid()
  ) or exists (
    select 1 from public.teams
    where id = p_team_id and leader_id = auth.uid()
  );
$$;

-- ── participates_in_scrim ───────────────────────────────────────────────────
-- Now also returns true when the caller leads a team in the scrim.
create or replace function public.participates_in_scrim(p_scrim_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.scrim_teams st
    join public.team_members tm on st.team_id = tm.team_id
    where st.scrim_id = p_scrim_id and tm.user_id = auth.uid()
  ) or exists (
    select 1 from public.scrim_teams st
    join public.teams t on st.team_id = t.id
    where st.scrim_id = p_scrim_id and t.leader_id = auth.uid()
  );
$$;
