-- Fix: profiles join returned null for teammates in production because
-- is_teammate_of() failed in the PostgREST embedded-resource RLS context.
--
-- Profile data (username, timezone, role) is not sensitive — the app already
-- exposes it via supabaseAdmin on the scrims and fillers pages. Making
-- profiles readable by all authenticated users is the correct policy for
-- a team-coordination app and removes the fragile cross-table RLS dependency.

create policy "Authenticated users can view profiles"
  on public.profiles for select
  using (auth.uid() is not null);
