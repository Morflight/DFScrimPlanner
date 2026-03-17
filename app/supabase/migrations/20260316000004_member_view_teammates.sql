-- Members could only see their own team_members row (user_id = auth.uid()).
-- This prevented the roster from showing other teammates.
create policy "Members can view teammates"
  on public.team_members for select
  using (public.is_team_member_of(team_id));
