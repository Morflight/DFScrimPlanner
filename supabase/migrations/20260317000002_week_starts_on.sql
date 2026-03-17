-- Add week_starts_on preference to profiles
-- Values: 'monday' (default, EU/APAC) or 'sunday' (NA)
ALTER TABLE public.profiles
  ADD COLUMN week_starts_on text NOT NULL DEFAULT 'monday';

-- Set 'sunday' for existing NA-timezone demo users
UPDATE public.profiles
SET week_starts_on = 'sunday'
WHERE timezone LIKE 'America/%';
