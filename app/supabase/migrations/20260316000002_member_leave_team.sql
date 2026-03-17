-- Members must be able to delete their own team_members row to leave a team.
-- The "own membership" policy only covered SELECT and UPDATE — DELETE was missing,
-- which caused leave-team to silently fail (RLS blocked the delete).
create policy "Member can leave team"
  on public.team_members for delete
  using (user_id = auth.uid());
