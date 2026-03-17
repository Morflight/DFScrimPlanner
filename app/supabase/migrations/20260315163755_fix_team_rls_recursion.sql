-- SECURITY DEFINER functions break RLS circular references.
-- Pattern: any cross-table lookup inside an RLS policy must go through a
-- SECURITY DEFINER function so the inner query bypasses RLS and cannot
-- trigger the same policy again.
--
-- Cycles fixed here:
--   team_members → teams → team_members  (the reported recursion)
--   scrims       → scrim_teams → scrims  (same pattern, fixed proactively)

-- ── Helper functions ──────────────────────────────────────────────────────────

create or replace function public.is_team_leader(p_team_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.teams
    where id = p_team_id and leader_id = auth.uid()
  );
$$;

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
  );
$$;

create or replace function public.shares_team_with(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.team_members tm1
    join public.team_members tm2 on tm1.team_id = tm2.team_id
    where tm1.user_id = auth.uid() and tm2.user_id = p_user_id
  );
$$;

create or replace function public.is_scrim_organizer(p_scrim_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.scrims
    where id = p_scrim_id and organizer_id = auth.uid()
  );
$$;

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
  );
$$;

-- ── teams ─────────────────────────────────────────────────────────────────────
-- Was: exists (select 1 from team_members …)  ← triggered team_members RLS → cycle

drop policy if exists "Members can view team" on public.teams;
create policy "Members can view team"
  on public.teams for select
  using (public.is_team_member_of(id));

-- ── team_members ──────────────────────────────────────────────────────────────
-- Was: exists (select 1 from teams …)  ← triggered teams RLS → cycle

drop policy if exists "Leader can manage members" on public.team_members;
create policy "Leader can manage members"
  on public.team_members for all
  using (public.is_team_leader(team_id));

-- ── availabilities ────────────────────────────────────────────────────────────
-- Was: self-join on team_members  ← triggered team_members RLS → cycle

drop policy if exists "Teammates can view teammate availability" on public.availabilities;
create policy "Teammates can view teammate availability"
  on public.availabilities for select
  using (public.shares_team_with(user_id));

-- ── scrims ────────────────────────────────────────────────────────────────────
-- Was: join scrim_teams + team_members  ← triggered scrim_teams RLS → cycle

drop policy if exists "Participants can view scrims" on public.scrims;
create policy "Participants can view scrims"
  on public.scrims for select
  using (public.participates_in_scrim(id));

-- ── scrim_teams ───────────────────────────────────────────────────────────────
-- Was: exists (select 1 from scrims …)  ← triggered scrims RLS → cycle
-- Was: exists (select 1 from team_members …)  ← triggered team_members RLS → cycle

drop policy if exists "Organizer can manage scrim teams" on public.scrim_teams;
create policy "Organizer can manage scrim teams"
  on public.scrim_teams for all
  using (public.is_scrim_organizer(scrim_id));

drop policy if exists "Participants can view scrim teams" on public.scrim_teams;
create policy "Participants can view scrim teams"
  on public.scrim_teams for select
  using (public.is_team_member_of(team_id));
