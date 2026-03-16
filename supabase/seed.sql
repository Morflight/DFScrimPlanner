-- ============================================================
-- Dev seed data — demo accounts
--
-- Admin:   admin@dev.local  / admin1234
-- Leaders: demo-<team>-lead@dev.local / test1234
-- Players: demo-<team>-<role>@dev.local / test1234
--
-- 6 demo teams × 3 players (1 leader + 2 members each)
-- Varied timezones and availability windows per player
--
-- Anchor = Monday of the week after seed date
-- Guaranteed scrim-matchable overlap:
--   anchor+Wed 19:00–22:00 UTC → Alpha + Bravo + Echo (3 teams, 3h)
--   anchor+Fri 20:00–23:00 UTC → Alpha + Echo (2 teams, 3h)
-- ============================================================

-- ── Admin account ────────────────────────────────────────────
do $$
declare
  v_user_id uuid := '00000000-0000-0000-0000-000000000001';
  v_email   text := 'admin@dev.local';
begin
  insert into auth.users (
    id, instance_id, aud, role,
    email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, is_sso_user, is_anonymous,
    created_at, updated_at
  ) values (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    v_email,
    extensions.crypt('admin1234', extensions.gen_salt('bf', 10)),
    now(),
    '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"username": "DevAdmin", "role": "admin"}'::jsonb,
    false, false, false,
    now(), now()
  ) on conflict (id) do nothing;

  insert into auth.identities (
    user_id, provider_id, provider, identity_data,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_user_id, v_email, 'email',
    jsonb_build_object('sub', v_user_id::text, 'email', v_email),
    now(), now(), now()
  ) on conflict (provider_id, provider) do nothing;
end $$;

-- ── Demo players (6 leaders + 12 players) ───────────────────
-- Team layout:
--   1. Demo Alpha Wolves  (EU evening)
--   2. Demo Bravo Hawks   (EU evening, shifted)
--   3. Demo Charlie Foxes (NA East evening)
--   4. Demo Delta Ravens  (NA West evening)
--   5. Demo Echo Storm    (Mixed EU/NA crossover)
--   6. Demo Foxtrot Vipers(Asia-Pacific daytime)
do $$
declare
  uids uuid[] := array[
    -- Leaders 1–6
    '00000000-0000-0000-1000-000000000001'::uuid,
    '00000000-0000-0000-1000-000000000002'::uuid,
    '00000000-0000-0000-1000-000000000003'::uuid,
    '00000000-0000-0000-1000-000000000004'::uuid,
    '00000000-0000-0000-1000-000000000005'::uuid,
    '00000000-0000-0000-1000-000000000006'::uuid,
    -- Players 1–12
    '00000000-0000-0000-2000-000000000001'::uuid,
    '00000000-0000-0000-2000-000000000002'::uuid,
    '00000000-0000-0000-2000-000000000003'::uuid,
    '00000000-0000-0000-2000-000000000004'::uuid,
    '00000000-0000-0000-2000-000000000005'::uuid,
    '00000000-0000-0000-2000-000000000006'::uuid,
    '00000000-0000-0000-2000-000000000007'::uuid,
    '00000000-0000-0000-2000-000000000008'::uuid,
    '00000000-0000-0000-2000-000000000009'::uuid,
    '00000000-0000-0000-2000-000000000010'::uuid,
    '00000000-0000-0000-2000-000000000011'::uuid,
    '00000000-0000-0000-2000-000000000012'::uuid
  ];
  emails text[] := array[
    'demo-alpha-lead@dev.local',  'demo-bravo-lead@dev.local',
    'demo-charlie-lead@dev.local','demo-delta-lead@dev.local',
    'demo-echo-lead@dev.local',   'demo-foxtrot-lead@dev.local',
    'demo-alpha-rifle@dev.local', 'demo-alpha-sniper@dev.local',
    'demo-bravo-rifle@dev.local', 'demo-bravo-sniper@dev.local',
    'demo-charlie-rifle@dev.local','demo-charlie-sniper@dev.local',
    'demo-delta-rifle@dev.local', 'demo-delta-sniper@dev.local',
    'demo-echo-rifle@dev.local',  'demo-echo-sniper@dev.local',
    'demo-foxtrot-rifle@dev.local','demo-foxtrot-sniper@dev.local'
  ];
  usernames text[] := array[
    'demo-AlphaLead',   'demo-BravoLead',
    'demo-CharlieLead', 'demo-DeltaLead',
    'demo-EchoLead',    'demo-FoxtrotLead',
    'demo-AlphaRifle',  'demo-AlphaSniper',
    'demo-BravoRifle',  'demo-BravoSniper',
    'demo-CharlieRifle','demo-CharlieSniper',
    'demo-DeltaRifle',  'demo-DeltaSniper',
    'demo-EchoRifle',   'demo-EchoSniper',
    'demo-FoxtrotRifle','demo-FoxtrotSniper'
  ];
  timezones text[] := array[
    -- Alpha: Western Europe
    'Europe/Paris',     'Europe/Paris',
    -- Bravo: Central/Eastern Europe
    'Europe/Warsaw',    'Europe/Berlin',
    -- Charlie: NA East
    'America/New_York', 'America/Toronto',
    -- Delta: NA West
    'America/Los_Angeles', 'America/Denver',
    -- Echo: Mixed EU/NA
    'Europe/London',    'America/New_York',
    -- Foxtrot: Asia-Pacific
    'Asia/Tokyo',       'Australia/Sydney',
    -- Alpha players
    'Europe/Berlin',    'Europe/London',
    -- Bravo players
    'Europe/Warsaw',    'Europe/Madrid',
    -- Charlie players
    'America/Toronto',  'America/Chicago',
    -- Delta players
    'America/Denver',   'America/Vancouver',
    -- Echo players
    'America/New_York', 'Europe/Berlin',
    -- Foxtrot players
    'Asia/Singapore',   'Australia/Sydney'
  ];
  roles text[] := array[
    'leader','leader','leader','leader','leader','leader',
    'player','player','player','player','player','player',
    'player','player','player','player','player','player'
  ];
  i int;
begin
  for i in 1..array_length(uids, 1) loop
    insert into auth.users (
      id, instance_id, aud, role,
      email, encrypted_password, email_confirmed_at,
      confirmation_token, recovery_token, email_change_token_new,
      email_change, email_change_token_current,
      raw_app_meta_data, raw_user_meta_data,
      is_super_admin, is_sso_user, is_anonymous,
      created_at, updated_at
    ) values (
      uids[i],
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      emails[i],
      extensions.crypt('test1234', extensions.gen_salt('bf', 10)),
      now(),
      '', '', '', '', '',
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      jsonb_build_object(
        'username', usernames[i],
        'role', roles[i],
        'timezone', timezones[i]
      ),
      false, false, false,
      now(), now()
    ) on conflict (id) do nothing;

    insert into auth.identities (
      user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) values (
      uids[i], emails[i], 'email',
      jsonb_build_object('sub', uids[i]::text, 'email', emails[i]),
      now(), now(), now()
    ) on conflict (provider_id, provider) do nothing;
  end loop;
end $$;

-- ── Teams ─────────────────────────────────────────────────────
insert into public.teams (id, name, leader_id) values
  ('00000000-0000-0000-3000-000000000001', 'Demo Alpha Wolves',   '00000000-0000-0000-1000-000000000001'),
  ('00000000-0000-0000-3000-000000000002', 'Demo Bravo Hawks',    '00000000-0000-0000-1000-000000000002'),
  ('00000000-0000-0000-3000-000000000003', 'Demo Charlie Foxes',  '00000000-0000-0000-1000-000000000003'),
  ('00000000-0000-0000-3000-000000000004', 'Demo Delta Ravens',   '00000000-0000-0000-1000-000000000004'),
  ('00000000-0000-0000-3000-000000000005', 'Demo Echo Storm',     '00000000-0000-0000-1000-000000000005'),
  ('00000000-0000-0000-3000-000000000006', 'Demo Foxtrot Vipers', '00000000-0000-0000-1000-000000000006')
on conflict (id) do nothing;

-- ── Team members (2 active members per team) ──────────────────
insert into public.team_members (team_id, user_id, invite_email, invite_token, status, activated_at) values
  -- Alpha Wolves
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000001','demo-alpha-rifle@dev.local', 'tok-a-r','active',now()),
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000002','demo-alpha-sniper@dev.local','tok-a-s','active',now()),
  -- Bravo Hawks
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000003','demo-bravo-rifle@dev.local', 'tok-b-r','active',now()),
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000004','demo-bravo-sniper@dev.local','tok-b-s','active',now()),
  -- Charlie Foxes
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000005','demo-charlie-rifle@dev.local', 'tok-c-r','active',now()),
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000006','demo-charlie-sniper@dev.local','tok-c-s','active',now()),
  -- Delta Ravens
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000007','demo-delta-rifle@dev.local', 'tok-d-r','active',now()),
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000008','demo-delta-sniper@dev.local','tok-d-s','active',now()),
  -- Echo Storm
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000009','demo-echo-rifle@dev.local', 'tok-e-r','active',now()),
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000010','demo-echo-sniper@dev.local','tok-e-s','active',now()),
  -- Foxtrot Vipers
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000011','demo-foxtrot-rifle@dev.local', 'tok-f-r','active',now()),
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000012','demo-foxtrot-sniper@dev.local','tok-f-s','active',now())
on conflict do nothing;

-- ── Availabilities ────────────────────────────────────────────
-- Anchor = Monday of next week from seed date.
-- Each player has slightly different windows (realistic: not everyone
-- is free at the exact same time).
--
-- Schedule overview (all times UTC):
--
-- ALPHA WOLVES (EU evening):
--   Lead:   Mon 17:00–22:00  Wed 16:00–22:00  Fri 18:00–23:00
--   Rifle:  Mon 17:30–21:30  Wed 16:30–22:00  Fri 18:00–22:30
--   Sniper: Mon 17:00–21:00  Wed 16:00–21:30  Fri 18:30–23:00
--
-- BRAVO HAWKS (EU evening, shifted):
--   Lead:   Tue 15:30–20:30  Wed 17:00–22:00  Thu 16:00–21:00
--   Rifle:  Tue 16:00–20:30  Wed 17:30–22:00  Thu 16:00–20:30
--   Sniper: Tue 15:30–20:00  Wed 17:00–21:30  Thu 16:30–21:00
--
-- CHARLIE FOXES (NA East evening):
--   Lead:   Mon 23:00–04:00+1  Wed 22:30–03:30+1  Sat 23:00–04:00+1
--   Rifle:  Mon 23:30–04:00+1  Wed 23:00–03:30+1  Sat 23:00–03:30+1
--   Sniper: Mon 23:00–03:30+1  Wed 22:30–03:00+1  Sat 23:30–04:00+1
--
-- DELTA RAVENS (NA West evening):
--   Lead:   Tue 02:00–07:00  Thu 01:30–06:30  Sat 02:00–07:00
--   Rifle:  Tue 02:30–07:00  Thu 02:00–06:30  Sat 02:00–06:30
--   Sniper: Tue 02:00–06:30  Thu 01:30–06:00  Sat 02:30–07:00
--
-- ECHO STORM (Mixed EU/NA crossover):
--   Lead:   Mon 20:00–01:00+1  Wed 19:00–00:00+1  Fri 20:00–01:00+1
--   Rifle:  Mon 20:30–01:00+1  Wed 19:30–00:00+1  Fri 20:00–00:30+1
--   Sniper: Mon 20:00–00:30+1  Wed 19:00–23:30     Fri 20:30–01:00+1
--
-- FOXTROT VIPERS (Asia-Pacific daytime):
--   Lead:   Tue 09:00–14:00  Thu 10:00–15:00  Sun 08:00–13:00
--   Rifle:  Tue 09:30–14:00  Thu 10:00–14:30  Sun 08:30–13:00
--   Sniper: Tue 09:00–13:30  Thu 10:30–15:00  Sun 08:00–12:30
--
-- SCRIM-MATCHABLE OVERLAPS:
--   Wed 19:00–21:30 UTC → Alpha (16:00–21:30) ∩ Bravo (17:00–21:30) ∩ Echo (19:00–23:30)
--     → All 3 teams overlap for ≥3h window: 19:00–21:30 = 2h30 minimum
--     → Actually: Alpha all 3 free 17:30–21:00, Bravo all 3 free 17:30–20:00,
--       Echo all 3 free 20:30–23:30... Let me recalc.
--     → Safe window: Wed 19:30–22:00 → Alpha ✓ Bravo ✓ (just) Echo ✓
--   Fri 20:00–22:30 UTC → Alpha (18:00–22:30) ∩ Echo (20:00–00:30)
--     → 2 teams overlap 20:00–22:30 = 2h30; with buffer from individual players ≥3h

do $$
declare
  anchor date := date_trunc('week', CURRENT_DATE + interval '7 days')::date;
  -- convenience: anchor + N days at HH:MM UTC
  -- We'll build timestamps inline below
begin
  -- ── ALPHA WOLVES ──────────────────────────────────────────
  -- Leader (L1): Mon 17:00–22:00, Wed 16:00–22:00, Fri 18:00–23:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000001', anchor + interval '0 days 17 hours',  anchor + interval '0 days 22 hours'),
    ('00000000-0000-0000-1000-000000000001', anchor + interval '2 days 16 hours',  anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-1000-000000000001', anchor + interval '4 days 18 hours',  anchor + interval '4 days 23 hours');
  -- Rifle (P1): Mon 17:30–21:30, Wed 16:30–22:00, Fri 18:00–22:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000001', anchor + interval '0 days 17 hours 30 minutes', anchor + interval '0 days 21 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000001', anchor + interval '2 days 16 hours 30 minutes', anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-2000-000000000001', anchor + interval '4 days 18 hours',             anchor + interval '4 days 22 hours 30 minutes');
  -- Sniper (P2): Mon 17:00–21:00, Wed 16:00–21:30, Fri 18:30–23:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000002', anchor + interval '0 days 17 hours',             anchor + interval '0 days 21 hours'),
    ('00000000-0000-0000-2000-000000000002', anchor + interval '2 days 16 hours',             anchor + interval '2 days 21 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000002', anchor + interval '4 days 18 hours 30 minutes',  anchor + interval '4 days 23 hours');

  -- ── BRAVO HAWKS ───────────────────────────────────────────
  -- Leader (L2): Tue 15:30–20:30, Wed 17:00–22:00, Thu 16:00–21:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000002', anchor + interval '1 day  15 hours 30 minutes', anchor + interval '1 day  20 hours 30 minutes'),
    ('00000000-0000-0000-1000-000000000002', anchor + interval '2 days 17 hours',            anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-1000-000000000002', anchor + interval '3 days 16 hours',            anchor + interval '3 days 21 hours');
  -- Rifle (P3): Tue 16:00–20:30, Wed 17:30–22:00, Thu 16:00–20:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000003', anchor + interval '1 day  16 hours',            anchor + interval '1 day  20 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000003', anchor + interval '2 days 17 hours 30 minutes', anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-2000-000000000003', anchor + interval '3 days 16 hours',            anchor + interval '3 days 20 hours 30 minutes');
  -- Sniper (P4): Tue 15:30–20:00, Wed 17:00–21:30, Thu 16:30–21:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000004', anchor + interval '1 day  15 hours 30 minutes', anchor + interval '1 day  20 hours'),
    ('00000000-0000-0000-2000-000000000004', anchor + interval '2 days 17 hours',            anchor + interval '2 days 21 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000004', anchor + interval '3 days 16 hours 30 minutes', anchor + interval '3 days 21 hours');

  -- ── CHARLIE FOXES ─────────────────────────────────────────
  -- Leader (L3): Mon 23:00–04:00+1, Wed 22:30–03:30+1, Sat 23:00–04:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000003', anchor + interval '0 days 23 hours', anchor + interval '1 day  4 hours'),
    ('00000000-0000-0000-1000-000000000003', anchor + interval '2 days 22 hours 30 minutes', anchor + interval '3 days 3 hours 30 minutes'),
    ('00000000-0000-0000-1000-000000000003', anchor + interval '5 days 23 hours', anchor + interval '6 days 4 hours');
  -- Rifle (P5): Mon 23:30–04:00+1, Wed 23:00–03:30+1, Sat 23:00–03:30+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000005', anchor + interval '0 days 23 hours 30 minutes', anchor + interval '1 day  4 hours'),
    ('00000000-0000-0000-2000-000000000005', anchor + interval '2 days 23 hours',            anchor + interval '3 days 3 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000005', anchor + interval '5 days 23 hours',            anchor + interval '6 days 3 hours 30 minutes');
  -- Sniper (P6): Mon 23:00–03:30+1, Wed 22:30–03:00+1, Sat 23:30–04:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000006', anchor + interval '0 days 23 hours',            anchor + interval '1 day  3 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000006', anchor + interval '2 days 22 hours 30 minutes', anchor + interval '3 days 3 hours'),
    ('00000000-0000-0000-2000-000000000006', anchor + interval '5 days 23 hours 30 minutes', anchor + interval '6 days 4 hours');

  -- ── DELTA RAVENS ──────────────────────────────────────────
  -- Leader (L4): Tue 02:00–07:00, Thu 01:30–06:30, Sat 02:00–07:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000004', anchor + interval '1 day  2 hours',             anchor + interval '1 day  7 hours'),
    ('00000000-0000-0000-1000-000000000004', anchor + interval '3 days 1 hour 30 minutes',   anchor + interval '3 days 6 hours 30 minutes'),
    ('00000000-0000-0000-1000-000000000004', anchor + interval '5 days 2 hours',             anchor + interval '5 days 7 hours');
  -- Rifle (P7): Tue 02:30–07:00, Thu 02:00–06:30, Sat 02:00–06:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000007', anchor + interval '1 day  2 hours 30 minutes',  anchor + interval '1 day  7 hours'),
    ('00000000-0000-0000-2000-000000000007', anchor + interval '3 days 2 hours',             anchor + interval '3 days 6 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000007', anchor + interval '5 days 2 hours',             anchor + interval '5 days 6 hours 30 minutes');
  -- Sniper (P8): Tue 02:00–06:30, Thu 01:30–06:00, Sat 02:30–07:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000008', anchor + interval '1 day  2 hours',             anchor + interval '1 day  6 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000008', anchor + interval '3 days 1 hour 30 minutes',   anchor + interval '3 days 6 hours'),
    ('00000000-0000-0000-2000-000000000008', anchor + interval '5 days 2 hours 30 minutes',  anchor + interval '5 days 7 hours');

  -- ── ECHO STORM ────────────────────────────────────────────
  -- Leader (L5): Mon 20:00–01:00+1, Wed 19:00–00:00+1, Fri 20:00–01:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000005', anchor + interval '0 days 20 hours', anchor + interval '1 day  1 hour'),
    ('00000000-0000-0000-1000-000000000005', anchor + interval '2 days 19 hours', anchor + interval '3 days 0 hours'),
    ('00000000-0000-0000-1000-000000000005', anchor + interval '4 days 20 hours', anchor + interval '5 days 1 hour');
  -- Rifle (P9): Mon 20:30–01:00+1, Wed 19:30–00:00+1, Fri 20:00–00:30+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000009', anchor + interval '0 days 20 hours 30 minutes', anchor + interval '1 day  1 hour'),
    ('00000000-0000-0000-2000-000000000009', anchor + interval '2 days 19 hours 30 minutes', anchor + interval '3 days 0 hours'),
    ('00000000-0000-0000-2000-000000000009', anchor + interval '4 days 20 hours',            anchor + interval '5 days 0 hours 30 minutes');
  -- Sniper (P10): Mon 20:00–00:30+1, Wed 19:00–23:30, Fri 20:30–01:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000010', anchor + interval '0 days 20 hours',            anchor + interval '1 day  0 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000010', anchor + interval '2 days 19 hours',            anchor + interval '2 days 23 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000010', anchor + interval '4 days 20 hours 30 minutes', anchor + interval '5 days 1 hour');

  -- ── FOXTROT VIPERS ────────────────────────────────────────
  -- Leader (L6): Tue 09:00–14:00, Thu 10:00–15:00, Sun 08:00–13:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000006', anchor + interval '1 day  9 hours',  anchor + interval '1 day  14 hours'),
    ('00000000-0000-0000-1000-000000000006', anchor + interval '3 days 10 hours', anchor + interval '3 days 15 hours'),
    ('00000000-0000-0000-1000-000000000006', anchor + interval '6 days 8 hours',  anchor + interval '6 days 13 hours');
  -- Rifle (P11): Tue 09:30–14:00, Thu 10:00–14:30, Sun 08:30–13:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000011', anchor + interval '1 day  9 hours 30 minutes', anchor + interval '1 day  14 hours'),
    ('00000000-0000-0000-2000-000000000011', anchor + interval '3 days 10 hours',           anchor + interval '3 days 14 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000011', anchor + interval '6 days 8 hours 30 minutes', anchor + interval '6 days 13 hours');
  -- Sniper (P12): Tue 09:00–13:30, Thu 10:30–15:00, Sun 08:00–12:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000012', anchor + interval '1 day  9 hours',             anchor + interval '1 day  13 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000012', anchor + interval '3 days 10 hours 30 minutes', anchor + interval '3 days 15 hours'),
    ('00000000-0000-0000-2000-000000000012', anchor + interval '6 days 8 hours',             anchor + interval '6 days 12 hours 30 minutes');
end $$;

-- ============================================================
-- OVERLAP VERIFICATION (for reference, not executed)
--
-- Note: time-first scrim matching checks team_members windows
-- (not leaders). A team is "available" if ANY one member's
-- window fully covers the 3h slot (.some(), not .every()).
--
-- Wednesday — per-player windows:
--   Alpha Rifle:  16:30–22:00  |  Alpha Sniper:  16:00–21:30
--   Bravo Rifle:  17:30–22:00  |  Bravo Sniper:  17:00–21:30
--   Echo  Rifle:  19:30–00:00  |  Echo  Sniper:  19:00–23:30
--
-- Wed 18:00 UTC (→ 21:00): Alpha ✓ (Rifle covers)  Bravo ✓ (Rifle covers)
-- Wed 19:00 UTC (→ 22:00): Alpha ✓ (Rifle 22:00≥22:00)  Bravo ✓ (Rifle)  Echo ✓ (Sniper)
--   ➜ Best demo slot: Wed 19:00 UTC → 3 teams available
--
-- Friday — per-player windows:
--   Alpha Rifle:  18:00–22:30  |  Alpha Sniper:  18:30–23:00
--   Echo  Rifle:  20:00–00:30  |  Echo  Sniper:  20:30–01:00
--
-- Fri 20:00 UTC (→ 23:00): Alpha ✓ (Sniper 23:00≥23:00)  Echo ✓ (Rifle)
--   ➜ Fri 20:00 UTC → 2 teams available
-- ============================================================
