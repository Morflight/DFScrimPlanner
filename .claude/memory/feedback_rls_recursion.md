---
name: RLS SECURITY DEFINER pattern
description: Any cross-table lookup in a Supabase RLS policy must use a SECURITY DEFINER function to avoid infinite recursion
type: feedback
---

Never write RLS policies that query other RLS-protected tables directly. Always use a `SECURITY DEFINER` function for cross-table lookups.

**Why:** This project has hit infinite recursion twice (`profiles` admin cycle, then `teams ↔ team_members` cycle). Direct `EXISTS (SELECT 1 FROM other_table …)` inside a policy causes Postgres to evaluate the other table's RLS policies, which can loop back.

**How to apply:** Before writing any policy with a subquery on another table, create a `SECURITY DEFINER` function in `supabase/migrations/` that performs the check. Document it in the helper functions table in `.claude/schema.md`. The existing helpers (`is_team_leader`, `is_team_member_of`, `shares_team_with`, `is_scrim_organizer`, `participates_in_scrim`, `is_admin`) cover most cases — use them instead of raw subqueries.
