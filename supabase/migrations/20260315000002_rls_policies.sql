-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.availabilities enable row level security;
alter table public.scrims enable row level security;
alter table public.scrim_teams enable row level security;

-- Profiles
create policy "Users can view own profile"
  on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- Teams
create policy "Leader can manage team"
  on public.teams for all using (auth.uid() = leader_id);
create policy "Members can view team"
  on public.teams for select using (
    exists (select 1 from public.team_members where team_id = teams.id and user_id = auth.uid())
  );

-- Team members
create policy "Leader can manage members"
  on public.team_members for all using (
    exists (select 1 from public.teams where id = team_members.team_id and leader_id = auth.uid())
  );
create policy "Member can view own membership"
  on public.team_members for select using (user_id = auth.uid());
create policy "Member can update own membership"
  on public.team_members for update using (user_id = auth.uid());

-- Availabilities
create policy "Users can manage own availability"
  on public.availabilities for all using (auth.uid() = user_id);
create policy "Teammates can view teammate availability"
  on public.availabilities for select using (
    exists (
      select 1 from public.team_members tm1
      join public.team_members tm2 on tm1.team_id = tm2.team_id
      where tm1.user_id = auth.uid() and tm2.user_id = availabilities.user_id
    )
  );
create policy "Filler availability is publicly readable"
  on public.availabilities for select using (
    exists (select 1 from public.profiles where id = availabilities.user_id and role = 'filler')
  );

-- Scrims
create policy "Organizer can manage scrims"
  on public.scrims for all using (auth.uid() = organizer_id);
create policy "Participants can view scrims"
  on public.scrims for select using (
    exists (
      select 1 from public.scrim_teams st
      join public.team_members tm on st.team_id = tm.team_id
      where st.scrim_id = scrims.id and tm.user_id = auth.uid()
    )
  );

-- Scrim teams
create policy "Organizer can manage scrim teams"
  on public.scrim_teams for all using (
    exists (select 1 from public.scrims where id = scrim_teams.scrim_id and organizer_id = auth.uid())
  );
create policy "Participants can view scrim teams"
  on public.scrim_teams for select using (
    exists (select 1 from public.team_members where team_id = scrim_teams.team_id and user_id = auth.uid())
  );
