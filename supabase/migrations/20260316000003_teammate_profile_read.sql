-- Team members couldn't read each other's profiles because the only SELECT
-- policy was "own profile" (auth.uid() = id). The profiles join on team_members
-- queries returned null for all teammates, leaving the roster blank.
create policy "Teammates can view each other's profiles"
  on public.profiles for select
  using (public.is_teammate_of(id));
