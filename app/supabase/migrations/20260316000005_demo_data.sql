-- ============================================================
-- Demo data: 6 teams × 3 players with varied availability
--
-- Append-only — every INSERT uses ON CONFLICT DO NOTHING.
-- Safe to run on a populated database; will not modify
-- existing rows or delete anything.
--
-- Accounts (password: test1234):
--   demo-alpha-lead@dev.local   demo-alpha-rifle@dev.local   demo-alpha-sniper@dev.local
--   demo-bravo-lead@dev.local   demo-bravo-rifle@dev.local   demo-bravo-sniper@dev.local
--   demo-charlie-lead@dev.local demo-charlie-rifle@dev.local demo-charlie-sniper@dev.local
--   demo-delta-lead@dev.local   demo-delta-rifle@dev.local   demo-delta-sniper@dev.local
--   demo-echo-lead@dev.local    demo-echo-rifle@dev.local    demo-echo-sniper@dev.local
--   demo-foxtrot-lead@dev.local demo-foxtrot-rifle@dev.local demo-foxtrot-sniper@dev.local
--
-- Scrim-matchable overlaps (anchor = Monday of next week from deploy):
--   Wed 19:00 UTC → Alpha + Bravo + Echo (3 teams)
--   Fri 20:00 UTC → Alpha + Echo (2 teams)
-- ============================================================

-- ── Demo auth users ─────────────────────────────────────────
do $$
declare
  uids uuid[] := array[
    '00000000-0000-0000-1000-000000000001'::uuid,
    '00000000-0000-0000-1000-000000000002'::uuid,
    '00000000-0000-0000-1000-000000000003'::uuid,
    '00000000-0000-0000-1000-000000000004'::uuid,
    '00000000-0000-0000-1000-000000000005'::uuid,
    '00000000-0000-0000-1000-000000000006'::uuid,
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
    'demo-alpha-lead@dev.local',    'demo-bravo-lead@dev.local',
    'demo-charlie-lead@dev.local',  'demo-delta-lead@dev.local',
    'demo-echo-lead@dev.local',     'demo-foxtrot-lead@dev.local',
    'demo-alpha-rifle@dev.local',   'demo-alpha-sniper@dev.local',
    'demo-bravo-rifle@dev.local',   'demo-bravo-sniper@dev.local',
    'demo-charlie-rifle@dev.local', 'demo-charlie-sniper@dev.local',
    'demo-delta-rifle@dev.local',   'demo-delta-sniper@dev.local',
    'demo-echo-rifle@dev.local',    'demo-echo-sniper@dev.local',
    'demo-foxtrot-rifle@dev.local', 'demo-foxtrot-sniper@dev.local'
  ];
  usernames text[] := array[
    'demo-AlphaLead',    'demo-BravoLead',
    'demo-CharlieLead',  'demo-DeltaLead',
    'demo-EchoLead',     'demo-FoxtrotLead',
    'demo-AlphaRifle',   'demo-AlphaSniper',
    'demo-BravoRifle',   'demo-BravoSniper',
    'demo-CharlieRifle', 'demo-CharlieSniper',
    'demo-DeltaRifle',   'demo-DeltaSniper',
    'demo-EchoRifle',    'demo-EchoSniper',
    'demo-FoxtrotRifle', 'demo-FoxtrotSniper'
  ];
  timezones text[] := array[
    'Europe/Paris',        'Europe/Warsaw',
    'America/New_York',    'America/Los_Angeles',
    'Europe/London',       'Asia/Tokyo',
    'Europe/Berlin',       'Europe/London',
    'Europe/Warsaw',       'Europe/Madrid',
    'America/Toronto',     'America/Chicago',
    'America/Denver',      'America/Vancouver',
    'America/New_York',    'Europe/Berlin',
    'Asia/Singapore',      'Australia/Sydney'
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

-- ── Demo teams ──────────────────────────────────────────────
insert into public.teams (id, name, leader_id) values
  ('00000000-0000-0000-3000-000000000001', 'Demo Alpha Wolves',   '00000000-0000-0000-1000-000000000001'),
  ('00000000-0000-0000-3000-000000000002', 'Demo Bravo Hawks',    '00000000-0000-0000-1000-000000000002'),
  ('00000000-0000-0000-3000-000000000003', 'Demo Charlie Foxes',  '00000000-0000-0000-1000-000000000003'),
  ('00000000-0000-0000-3000-000000000004', 'Demo Delta Ravens',   '00000000-0000-0000-1000-000000000004'),
  ('00000000-0000-0000-3000-000000000005', 'Demo Echo Storm',     '00000000-0000-0000-1000-000000000005'),
  ('00000000-0000-0000-3000-000000000006', 'Demo Foxtrot Vipers', '00000000-0000-0000-1000-000000000006')
on conflict (id) do nothing;

-- ── Demo team members ───────────────────────────────────────
insert into public.team_members (team_id, user_id, invite_email, invite_token, status, activated_at) values
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000001','demo-alpha-rifle@dev.local',   'tok-demo-a-r','active',now()),
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000002','demo-alpha-sniper@dev.local',  'tok-demo-a-s','active',now()),
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000003','demo-bravo-rifle@dev.local',   'tok-demo-b-r','active',now()),
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000004','demo-bravo-sniper@dev.local',  'tok-demo-b-s','active',now()),
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000005','demo-charlie-rifle@dev.local', 'tok-demo-c-r','active',now()),
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000006','demo-charlie-sniper@dev.local','tok-demo-c-s','active',now()),
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000007','demo-delta-rifle@dev.local',   'tok-demo-d-r','active',now()),
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000008','demo-delta-sniper@dev.local',  'tok-demo-d-s','active',now()),
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000009','demo-echo-rifle@dev.local',    'tok-demo-e-r','active',now()),
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000010','demo-echo-sniper@dev.local',   'tok-demo-e-s','active',now()),
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000011','demo-foxtrot-rifle@dev.local', 'tok-demo-f-r','active',now()),
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000012','demo-foxtrot-sniper@dev.local','tok-demo-f-s','active',now())
on conflict do nothing;

-- ── Demo availabilities ─────────────────────────────────────
-- Anchor = Monday of the week after migration runs.
-- Per-player windows are staggered ±30min for realism.
do $$
declare
  anchor date := date_trunc('week', CURRENT_DATE + interval '7 days')::date;
begin
  -- ALPHA WOLVES (EU evening)
  -- Leader: Mon 17:00–22:00, Wed 16:00–22:00, Fri 18:00–23:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000001', anchor + interval '0 days 17 hours',  anchor + interval '0 days 22 hours'),
    ('00000000-0000-0000-1000-000000000001', anchor + interval '2 days 16 hours',  anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-1000-000000000001', anchor + interval '4 days 18 hours',  anchor + interval '4 days 23 hours');
  -- Rifle: Mon 17:30–21:30, Wed 16:30–22:00, Fri 18:00–22:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000001', anchor + interval '0 days 17 hours 30 minutes', anchor + interval '0 days 21 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000001', anchor + interval '2 days 16 hours 30 minutes', anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-2000-000000000001', anchor + interval '4 days 18 hours',             anchor + interval '4 days 22 hours 30 minutes');
  -- Sniper: Mon 17:00–21:00, Wed 16:00–21:30, Fri 18:30–23:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000002', anchor + interval '0 days 17 hours',             anchor + interval '0 days 21 hours'),
    ('00000000-0000-0000-2000-000000000002', anchor + interval '2 days 16 hours',             anchor + interval '2 days 21 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000002', anchor + interval '4 days 18 hours 30 minutes',  anchor + interval '4 days 23 hours');

  -- BRAVO HAWKS (EU evening, shifted)
  -- Leader: Tue 15:30–20:30, Wed 17:00–22:00, Thu 16:00–21:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000002', anchor + interval '1 day  15 hours 30 minutes', anchor + interval '1 day  20 hours 30 minutes'),
    ('00000000-0000-0000-1000-000000000002', anchor + interval '2 days 17 hours',            anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-1000-000000000002', anchor + interval '3 days 16 hours',            anchor + interval '3 days 21 hours');
  -- Rifle: Tue 16:00–20:30, Wed 17:30–22:00, Thu 16:00–20:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000003', anchor + interval '1 day  16 hours',            anchor + interval '1 day  20 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000003', anchor + interval '2 days 17 hours 30 minutes', anchor + interval '2 days 22 hours'),
    ('00000000-0000-0000-2000-000000000003', anchor + interval '3 days 16 hours',            anchor + interval '3 days 20 hours 30 minutes');
  -- Sniper: Tue 15:30–20:00, Wed 17:00–21:30, Thu 16:30–21:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000004', anchor + interval '1 day  15 hours 30 minutes', anchor + interval '1 day  20 hours'),
    ('00000000-0000-0000-2000-000000000004', anchor + interval '2 days 17 hours',            anchor + interval '2 days 21 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000004', anchor + interval '3 days 16 hours 30 minutes', anchor + interval '3 days 21 hours');

  -- CHARLIE FOXES (NA East evening)
  -- Leader: Mon 23:00–04:00+1, Wed 22:30–03:30+1, Sat 23:00–04:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000003', anchor + interval '0 days 23 hours', anchor + interval '1 day  4 hours'),
    ('00000000-0000-0000-1000-000000000003', anchor + interval '2 days 22 hours 30 minutes', anchor + interval '3 days 3 hours 30 minutes'),
    ('00000000-0000-0000-1000-000000000003', anchor + interval '5 days 23 hours', anchor + interval '6 days 4 hours');
  -- Rifle: Mon 23:30–04:00+1, Wed 23:00–03:30+1, Sat 23:00–03:30+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000005', anchor + interval '0 days 23 hours 30 minutes', anchor + interval '1 day  4 hours'),
    ('00000000-0000-0000-2000-000000000005', anchor + interval '2 days 23 hours',            anchor + interval '3 days 3 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000005', anchor + interval '5 days 23 hours',            anchor + interval '6 days 3 hours 30 minutes');
  -- Sniper: Mon 23:00–03:30+1, Wed 22:30–03:00+1, Sat 23:30–04:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000006', anchor + interval '0 days 23 hours',            anchor + interval '1 day  3 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000006', anchor + interval '2 days 22 hours 30 minutes', anchor + interval '3 days 3 hours'),
    ('00000000-0000-0000-2000-000000000006', anchor + interval '5 days 23 hours 30 minutes', anchor + interval '6 days 4 hours');

  -- DELTA RAVENS (NA West evening)
  -- Leader: Tue 02:00–07:00, Thu 01:30–06:30, Sat 02:00–07:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000004', anchor + interval '1 day  2 hours',             anchor + interval '1 day  7 hours'),
    ('00000000-0000-0000-1000-000000000004', anchor + interval '3 days 1 hour 30 minutes',   anchor + interval '3 days 6 hours 30 minutes'),
    ('00000000-0000-0000-1000-000000000004', anchor + interval '5 days 2 hours',             anchor + interval '5 days 7 hours');
  -- Rifle: Tue 02:30–07:00, Thu 02:00–06:30, Sat 02:00–06:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000007', anchor + interval '1 day  2 hours 30 minutes',  anchor + interval '1 day  7 hours'),
    ('00000000-0000-0000-2000-000000000007', anchor + interval '3 days 2 hours',             anchor + interval '3 days 6 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000007', anchor + interval '5 days 2 hours',             anchor + interval '5 days 6 hours 30 minutes');
  -- Sniper: Tue 02:00–06:30, Thu 01:30–06:00, Sat 02:30–07:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000008', anchor + interval '1 day  2 hours',             anchor + interval '1 day  6 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000008', anchor + interval '3 days 1 hour 30 minutes',   anchor + interval '3 days 6 hours'),
    ('00000000-0000-0000-2000-000000000008', anchor + interval '5 days 2 hours 30 minutes',  anchor + interval '5 days 7 hours');

  -- ECHO STORM (Mixed EU/NA crossover)
  -- Leader: Mon 20:00–01:00+1, Wed 19:00–00:00+1, Fri 20:00–01:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000005', anchor + interval '0 days 20 hours', anchor + interval '1 day  1 hour'),
    ('00000000-0000-0000-1000-000000000005', anchor + interval '2 days 19 hours', anchor + interval '3 days 0 hours'),
    ('00000000-0000-0000-1000-000000000005', anchor + interval '4 days 20 hours', anchor + interval '5 days 1 hour');
  -- Rifle: Mon 20:30–01:00+1, Wed 19:30–00:00+1, Fri 20:00–00:30+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000009', anchor + interval '0 days 20 hours 30 minutes', anchor + interval '1 day  1 hour'),
    ('00000000-0000-0000-2000-000000000009', anchor + interval '2 days 19 hours 30 minutes', anchor + interval '3 days 0 hours'),
    ('00000000-0000-0000-2000-000000000009', anchor + interval '4 days 20 hours',            anchor + interval '5 days 0 hours 30 minutes');
  -- Sniper: Mon 20:00–00:30+1, Wed 19:00–23:30, Fri 20:30–01:00+1
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000010', anchor + interval '0 days 20 hours',            anchor + interval '1 day  0 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000010', anchor + interval '2 days 19 hours',            anchor + interval '2 days 23 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000010', anchor + interval '4 days 20 hours 30 minutes', anchor + interval '5 days 1 hour');

  -- FOXTROT VIPERS (Asia-Pacific daytime)
  -- Leader: Tue 09:00–14:00, Thu 10:00–15:00, Sun 08:00–13:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000006', anchor + interval '1 day  9 hours',  anchor + interval '1 day  14 hours'),
    ('00000000-0000-0000-1000-000000000006', anchor + interval '3 days 10 hours', anchor + interval '3 days 15 hours'),
    ('00000000-0000-0000-1000-000000000006', anchor + interval '6 days 8 hours',  anchor + interval '6 days 13 hours');
  -- Rifle: Tue 09:30–14:00, Thu 10:00–14:30, Sun 08:30–13:00
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000011', anchor + interval '1 day  9 hours 30 minutes', anchor + interval '1 day  14 hours'),
    ('00000000-0000-0000-2000-000000000011', anchor + interval '3 days 10 hours',           anchor + interval '3 days 14 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000011', anchor + interval '6 days 8 hours 30 minutes', anchor + interval '6 days 13 hours');
  -- Sniper: Tue 09:00–13:30, Thu 10:30–15:00, Sun 08:00–12:30
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-2000-000000000012', anchor + interval '1 day  9 hours',             anchor + interval '1 day  13 hours 30 minutes'),
    ('00000000-0000-0000-2000-000000000012', anchor + interval '3 days 10 hours 30 minutes', anchor + interval '3 days 15 hours'),
    ('00000000-0000-0000-2000-000000000012', anchor + interval '6 days 8 hours',             anchor + interval '6 days 12 hours 30 minutes');
end $$;
