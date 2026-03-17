-- The 3-hour minimum belongs in slot-matching logic, not in the schema.
-- With the grid UI users save granular 30-min slots; the DB should store
-- whatever they select. Scrim matching already filters for ≥3h overlaps.
alter table public.availabilities
  drop constraint valid_window;
