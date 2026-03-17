-- ============================================================
-- Expanded demo data: 10 teams, 42 players, 8 scrims
--
-- Replaces the previous 6-team demo data from 20260316000005.
-- Deletes all demo-* users and related data, then re-inserts.
-- ============================================================

-- ── Clean up old demo data ─────────────────────────────────
-- Order matters: child tables first, then parents.

-- scrim_teams for demo scrims
delete from public.scrim_teams
where scrim_id in (
  select id from public.scrims
  where organizer_id in (select id from auth.users where email like 'demo-%@dev.local')
);

-- scrims by demo organizers
delete from public.scrims
where organizer_id in (select id from auth.users where email like 'demo-%@dev.local');

-- availabilities for demo users
delete from public.availabilities
where user_id in (select id from auth.users where email like 'demo-%@dev.local');

-- team_members for demo teams
delete from public.team_members
where team_id in (
  select id from public.teams
  where leader_id in (select id from auth.users where email like 'demo-%@dev.local')
);

-- teams led by demo users
delete from public.teams
where leader_id in (select id from auth.users where email like 'demo-%@dev.local');

-- profiles for demo users
delete from public.profiles
where id in (select id from auth.users where email like 'demo-%@dev.local');

-- auth identities and users
delete from auth.identities
where user_id in (select id from auth.users where email like 'demo-%@dev.local');

delete from auth.users
where email like 'demo-%@dev.local';

-- ── Demo auth users (10 leaders + 30 players + 2 fillers) ──
do $$
declare
  uids uuid[] := array[
    '00000000-0000-0000-1000-000000000001'::uuid,
    '00000000-0000-0000-1000-000000000002'::uuid,
    '00000000-0000-0000-1000-000000000003'::uuid,
    '00000000-0000-0000-1000-000000000004'::uuid,
    '00000000-0000-0000-1000-000000000005'::uuid,
    '00000000-0000-0000-1000-000000000006'::uuid,
    '00000000-0000-0000-1000-000000000007'::uuid,
    '00000000-0000-0000-1000-000000000008'::uuid,
    '00000000-0000-0000-1000-000000000009'::uuid,
    '00000000-0000-0000-1000-000000000010'::uuid,
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
    '00000000-0000-0000-2000-000000000012'::uuid,
    '00000000-0000-0000-2000-000000000013'::uuid,
    '00000000-0000-0000-2000-000000000014'::uuid,
    '00000000-0000-0000-2000-000000000015'::uuid,
    '00000000-0000-0000-2000-000000000016'::uuid,
    '00000000-0000-0000-2000-000000000017'::uuid,
    '00000000-0000-0000-2000-000000000018'::uuid,
    '00000000-0000-0000-2000-000000000019'::uuid,
    '00000000-0000-0000-2000-000000000020'::uuid,
    '00000000-0000-0000-2000-000000000021'::uuid,
    '00000000-0000-0000-2000-000000000022'::uuid,
    '00000000-0000-0000-2000-000000000023'::uuid,
    '00000000-0000-0000-2000-000000000024'::uuid,
    '00000000-0000-0000-2000-000000000025'::uuid,
    '00000000-0000-0000-2000-000000000026'::uuid,
    '00000000-0000-0000-2000-000000000027'::uuid,
    '00000000-0000-0000-2000-000000000028'::uuid,
    '00000000-0000-0000-2000-000000000029'::uuid,
    '00000000-0000-0000-2000-000000000030'::uuid,
    '00000000-0000-0000-4000-000000000001'::uuid,
    '00000000-0000-0000-4000-000000000002'::uuid
  ];
  emails text[] := array[
    'demo-alpha-lead@dev.local',   'demo-bravo-lead@dev.local',
    'demo-charlie-lead@dev.local', 'demo-delta-lead@dev.local',
    'demo-echo-lead@dev.local',    'demo-foxtrot-lead@dev.local',
    'demo-golf-lead@dev.local',    'demo-hotel-lead@dev.local',
    'demo-india-lead@dev.local',   'demo-juliet-lead@dev.local',
    'demo-alpha-rifle@dev.local',  'demo-alpha-sniper@dev.local',  'demo-alpha-support@dev.local',
    'demo-bravo-rifle@dev.local',  'demo-bravo-sniper@dev.local',  'demo-bravo-support@dev.local',
    'demo-charlie-rifle@dev.local','demo-charlie-sniper@dev.local','demo-charlie-support@dev.local',
    'demo-delta-rifle@dev.local',  'demo-delta-sniper@dev.local',  'demo-delta-support@dev.local',
    'demo-echo-rifle@dev.local',   'demo-echo-sniper@dev.local',   'demo-echo-support@dev.local',
    'demo-foxtrot-rifle@dev.local','demo-foxtrot-sniper@dev.local','demo-foxtrot-support@dev.local',
    'demo-golf-rifle@dev.local',   'demo-golf-sniper@dev.local',   'demo-golf-support@dev.local',
    'demo-hotel-rifle@dev.local',  'demo-hotel-sniper@dev.local',  'demo-hotel-support@dev.local',
    'demo-india-rifle@dev.local',  'demo-india-sniper@dev.local',  'demo-india-support@dev.local',
    'demo-juliet-rifle@dev.local', 'demo-juliet-sniper@dev.local', 'demo-juliet-support@dev.local',
    'demo-filler-1@dev.local',     'demo-filler-2@dev.local'
  ];
  usernames text[] := array[
    'demo-AlphaWolf',   'demo-HawkEye',
    'demo-FoxHound',    'demo-RavenClaw',
    'demo-StormRider',  'demo-ViperFang',
    'demo-TitanForce',  'demo-PhantomX',
    'demo-ReaperMain',  'demo-SpecterOps',
    'demo-RazorAim',    'demo-GhostShot',   'demo-IronSights',
    'demo-BlazeRush',   'demo-StormBreak',  'demo-NightOwl',
    'demo-ViperStrike', 'demo-ThunderClap', 'demo-ShadowStep',
    'demo-FrostBite',   'demo-DeadEye',     'demo-SteelNerve',
    'demo-PhantomAce',  'demo-NeonBlade',   'demo-CyberPulse',
    'demo-DragonFire',  'demo-TigerClaw',   'demo-SilentWind',
    'demo-CrushMode',   'demo-WarHammer',   'demo-IronWill',
    'demo-DarkMatter',  'demo-VoidWalker',  'demo-NullPoint',
    'demo-SoulHarvest', 'demo-GrimShade',   'demo-BoneCrush',
    'demo-GhostProto',  'demo-ShadowOps',   'demo-MidnightRun',
    'demo-LoneStar',    'demo-RogueAgent'
  ];
  timezones text[] := array[
    'Europe/Paris',         'Europe/Warsaw',
    'America/New_York',     'America/Los_Angeles',
    'Europe/London',        'Asia/Tokyo',
    'Europe/Berlin',        'America/New_York',
    'America/Denver',       'Europe/London',
    'Europe/Berlin',        'Europe/London',        'Europe/Paris',
    'Europe/Warsaw',        'Europe/Madrid',        'Europe/Bucharest',
    'America/Toronto',      'America/Chicago',      'America/New_York',
    'America/Denver',       'America/Vancouver',    'America/Los_Angeles',
    'America/New_York',     'Europe/Berlin',        'Europe/London',
    'Asia/Singapore',       'Australia/Sydney',     'Asia/Tokyo',
    'Europe/Amsterdam',     'Europe/Stockholm',     'Europe/Berlin',
    'America/New_York',     'America/Toronto',      'America/Chicago',
    'America/Denver',       'America/Phoenix',      'America/Los_Angeles',
    'Europe/Dublin',        'America/Toronto',      'Europe/London',
    'Europe/Paris',         'America/New_York'
  ];
  roles text[] := array[
    'leader','leader','leader','leader','leader','leader','leader','leader','leader','leader',
    'player','player','player','player','player','player','player','player','player','player',
    'player','player','player','player','player','player','player','player','player','player',
    'player','player','player','player','player','player','player','player','player','player',
    'filler','filler'
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

-- ── Demo teams ─────────────────────────────────────────────
insert into public.teams (id, name, leader_id) values
  ('00000000-0000-0000-3000-000000000001', 'Demo Alpha Wolves',    '00000000-0000-0000-1000-000000000001'),
  ('00000000-0000-0000-3000-000000000002', 'Demo Bravo Hawks',     '00000000-0000-0000-1000-000000000002'),
  ('00000000-0000-0000-3000-000000000003', 'Demo Charlie Foxes',   '00000000-0000-0000-1000-000000000003'),
  ('00000000-0000-0000-3000-000000000004', 'Demo Delta Ravens',    '00000000-0000-0000-1000-000000000004'),
  ('00000000-0000-0000-3000-000000000005', 'Demo Echo Storm',      '00000000-0000-0000-1000-000000000005'),
  ('00000000-0000-0000-3000-000000000006', 'Demo Foxtrot Vipers',  '00000000-0000-0000-1000-000000000006'),
  ('00000000-0000-0000-3000-000000000007', 'Demo Golf Titans',     '00000000-0000-0000-1000-000000000007'),
  ('00000000-0000-0000-3000-000000000008', 'Demo Hotel Phantoms',  '00000000-0000-0000-1000-000000000008'),
  ('00000000-0000-0000-3000-000000000009', 'Demo India Reapers',   '00000000-0000-0000-1000-000000000009'),
  ('00000000-0000-0000-3000-000000000010', 'Demo Juliet Specters', '00000000-0000-0000-1000-000000000010')
on conflict (id) do nothing;

-- ── Demo team members (3 per team) ─────────────────────────
insert into public.team_members (team_id, user_id, invite_email, invite_token, status, activated_at) values
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000001','demo-alpha-rifle@dev.local',   'tok-a-r','active',now()),
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000002','demo-alpha-sniper@dev.local',  'tok-a-s','active',now()),
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000003','demo-alpha-support@dev.local', 'tok-a-u','active',now()),
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000004','demo-bravo-rifle@dev.local',   'tok-b-r','active',now()),
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000005','demo-bravo-sniper@dev.local',  'tok-b-s','active',now()),
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000006','demo-bravo-support@dev.local', 'tok-b-u','active',now()),
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000007','demo-charlie-rifle@dev.local', 'tok-c-r','active',now()),
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000008','demo-charlie-sniper@dev.local','tok-c-s','active',now()),
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000009','demo-charlie-support@dev.local','tok-c-u','active',now()),
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000010','demo-delta-rifle@dev.local',   'tok-d-r','active',now()),
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000011','demo-delta-sniper@dev.local',  'tok-d-s','active',now()),
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000012','demo-delta-support@dev.local', 'tok-d-u','active',now()),
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000013','demo-echo-rifle@dev.local',    'tok-e-r','active',now()),
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000014','demo-echo-sniper@dev.local',   'tok-e-s','active',now()),
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000015','demo-echo-support@dev.local',  'tok-e-u','active',now()),
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000016','demo-foxtrot-rifle@dev.local', 'tok-f-r','active',now()),
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000017','demo-foxtrot-sniper@dev.local','tok-f-s','active',now()),
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000018','demo-foxtrot-support@dev.local','tok-f-u','active',now()),
  ('00000000-0000-0000-3000-000000000007','00000000-0000-0000-2000-000000000019','demo-golf-rifle@dev.local',    'tok-g-r','active',now()),
  ('00000000-0000-0000-3000-000000000007','00000000-0000-0000-2000-000000000020','demo-golf-sniper@dev.local',   'tok-g-s','active',now()),
  ('00000000-0000-0000-3000-000000000007','00000000-0000-0000-2000-000000000021','demo-golf-support@dev.local',  'tok-g-u','active',now()),
  ('00000000-0000-0000-3000-000000000008','00000000-0000-0000-2000-000000000022','demo-hotel-rifle@dev.local',   'tok-h-r','active',now()),
  ('00000000-0000-0000-3000-000000000008','00000000-0000-0000-2000-000000000023','demo-hotel-sniper@dev.local',  'tok-h-s','active',now()),
  ('00000000-0000-0000-3000-000000000008','00000000-0000-0000-2000-000000000024','demo-hotel-support@dev.local', 'tok-h-u','active',now()),
  ('00000000-0000-0000-3000-000000000009','00000000-0000-0000-2000-000000000025','demo-india-rifle@dev.local',   'tok-i-r','active',now()),
  ('00000000-0000-0000-3000-000000000009','00000000-0000-0000-2000-000000000026','demo-india-sniper@dev.local',  'tok-i-s','active',now()),
  ('00000000-0000-0000-3000-000000000009','00000000-0000-0000-2000-000000000027','demo-india-support@dev.local', 'tok-i-u','active',now()),
  ('00000000-0000-0000-3000-000000000010','00000000-0000-0000-2000-000000000028','demo-juliet-rifle@dev.local',  'tok-j-r','active',now()),
  ('00000000-0000-0000-3000-000000000010','00000000-0000-0000-2000-000000000029','demo-juliet-sniper@dev.local', 'tok-j-s','active',now()),
  ('00000000-0000-0000-3000-000000000010','00000000-0000-0000-2000-000000000030','demo-juliet-support@dev.local','tok-j-u','active',now())
on conflict do nothing;

-- ── Demo availabilities (5 windows per player) ─────────────
do $$
declare
  a date := date_trunc('week', CURRENT_DATE + interval '7 days')::date;
begin
  -- ALPHA WOLVES (EU evening 17–23 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000001', a + interval '0d 17h',     a + interval '0d 23h'),
    ('00000000-0000-0000-1000-000000000001', a + interval '1d 18h',     a + interval '1d 22h 30m'),
    ('00000000-0000-0000-1000-000000000001', a + interval '2d 16h 30m', a + interval '2d 22h'),
    ('00000000-0000-0000-1000-000000000001', a + interval '4d 17h',     a + interval '4d 23h'),
    ('00000000-0000-0000-1000-000000000001', a + interval '5d 16h',     a + interval '5d 21h'),
    ('00000000-0000-0000-2000-000000000001', a + interval '0d 17h 30m', a + interval '0d 22h'),
    ('00000000-0000-0000-2000-000000000001', a + interval '1d 18h',     a + interval '1d 22h'),
    ('00000000-0000-0000-2000-000000000001', a + interval '2d 17h',     a + interval '2d 22h'),
    ('00000000-0000-0000-2000-000000000001', a + interval '4d 17h 30m', a + interval '4d 22h 30m'),
    ('00000000-0000-0000-2000-000000000001', a + interval '5d 16h 30m', a + interval '5d 21h 30m'),
    ('00000000-0000-0000-2000-000000000002', a + interval '0d 17h',     a + interval '0d 21h 30m'),
    ('00000000-0000-0000-2000-000000000002', a + interval '1d 18h 30m', a + interval '1d 22h 30m'),
    ('00000000-0000-0000-2000-000000000002', a + interval '2d 16h 30m', a + interval '2d 21h 30m'),
    ('00000000-0000-0000-2000-000000000002', a + interval '4d 18h',     a + interval '4d 23h'),
    ('00000000-0000-0000-2000-000000000002', a + interval '5d 16h',     a + interval '5d 21h'),
    ('00000000-0000-0000-2000-000000000003', a + interval '0d 18h',     a + interval '0d 22h'),
    ('00000000-0000-0000-2000-000000000003', a + interval '2d 17h',     a + interval '2d 22h'),
    ('00000000-0000-0000-2000-000000000003', a + interval '3d 17h',     a + interval '3d 21h 30m'),
    ('00000000-0000-0000-2000-000000000003', a + interval '4d 17h 30m', a + interval '4d 22h 30m'),
    ('00000000-0000-0000-2000-000000000003', a + interval '5d 16h 30m', a + interval '5d 21h 30m');

  -- BRAVO HAWKS (EU evening 16–22 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000002', a + interval '0d 16h',     a + interval '0d 21h'),
    ('00000000-0000-0000-1000-000000000002', a + interval '1d 16h 30m', a + interval '1d 21h 30m'),
    ('00000000-0000-0000-1000-000000000002', a + interval '2d 16h',     a + interval '2d 22h'),
    ('00000000-0000-0000-1000-000000000002', a + interval '3d 16h',     a + interval '3d 21h'),
    ('00000000-0000-0000-1000-000000000002', a + interval '5d 15h 30m', a + interval '5d 20h 30m'),
    ('00000000-0000-0000-2000-000000000004', a + interval '0d 16h 30m', a + interval '0d 21h 30m'),
    ('00000000-0000-0000-2000-000000000004', a + interval '1d 16h',     a + interval '1d 21h'),
    ('00000000-0000-0000-2000-000000000004', a + interval '2d 16h 30m', a + interval '2d 22h'),
    ('00000000-0000-0000-2000-000000000004', a + interval '3d 16h 30m', a + interval '3d 21h 30m'),
    ('00000000-0000-0000-2000-000000000004', a + interval '5d 16h',     a + interval '5d 21h'),
    ('00000000-0000-0000-2000-000000000005', a + interval '0d 16h',     a + interval '0d 20h 30m'),
    ('00000000-0000-0000-2000-000000000005', a + interval '1d 17h',     a + interval '1d 21h 30m'),
    ('00000000-0000-0000-2000-000000000005', a + interval '2d 16h',     a + interval '2d 21h 30m'),
    ('00000000-0000-0000-2000-000000000005', a + interval '3d 16h',     a + interval '3d 21h'),
    ('00000000-0000-0000-2000-000000000005', a + interval '5d 15h 30m', a + interval '5d 20h'),
    ('00000000-0000-0000-2000-000000000006', a + interval '1d 16h',     a + interval '1d 21h'),
    ('00000000-0000-0000-2000-000000000006', a + interval '2d 17h',     a + interval '2d 22h'),
    ('00000000-0000-0000-2000-000000000006', a + interval '3d 16h 30m', a + interval '3d 21h 30m'),
    ('00000000-0000-0000-2000-000000000006', a + interval '4d 16h',     a + interval '4d 21h'),
    ('00000000-0000-0000-2000-000000000006', a + interval '5d 16h',     a + interval '5d 20h 30m');

  -- CHARLIE FOXES (NA East 23–04 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000003', a + interval '0d 23h',     a + interval '1d 4h'),
    ('00000000-0000-0000-1000-000000000003', a + interval '2d 22h 30m', a + interval '3d 3h 30m'),
    ('00000000-0000-0000-1000-000000000003', a + interval '3d 23h',     a + interval '4d 4h'),
    ('00000000-0000-0000-1000-000000000003', a + interval '4d 23h 30m', a + interval '5d 4h'),
    ('00000000-0000-0000-1000-000000000003', a + interval '5d 22h 30m', a + interval '6d 4h'),
    ('00000000-0000-0000-2000-000000000007', a + interval '0d 23h 30m', a + interval '1d 4h'),
    ('00000000-0000-0000-2000-000000000007', a + interval '2d 23h',     a + interval '3d 3h 30m'),
    ('00000000-0000-0000-2000-000000000007', a + interval '3d 23h',     a + interval '4d 3h 30m'),
    ('00000000-0000-0000-2000-000000000007', a + interval '4d 23h',     a + interval '5d 4h'),
    ('00000000-0000-0000-2000-000000000007', a + interval '5d 23h',     a + interval '6d 4h'),
    ('00000000-0000-0000-2000-000000000008', a + interval '0d 23h',     a + interval '1d 3h 30m'),
    ('00000000-0000-0000-2000-000000000008', a + interval '2d 22h 30m', a + interval '3d 3h'),
    ('00000000-0000-0000-2000-000000000008', a + interval '3d 23h 30m', a + interval '4d 4h 30m'),
    ('00000000-0000-0000-2000-000000000008', a + interval '5d 22h 30m', a + interval '6d 3h 30m'),
    ('00000000-0000-0000-2000-000000000008', a + interval '6d 23h',     a + interval '7d 4h'),
    ('00000000-0000-0000-2000-000000000009', a + interval '2d 23h',     a + interval '3d 4h'),
    ('00000000-0000-0000-2000-000000000009', a + interval '3d 23h',     a + interval '4d 3h 30m'),
    ('00000000-0000-0000-2000-000000000009', a + interval '4d 23h',     a + interval '5d 3h 30m'),
    ('00000000-0000-0000-2000-000000000009', a + interval '5d 23h',     a + interval '6d 4h'),
    ('00000000-0000-0000-2000-000000000009', a + interval '6d 23h 30m', a + interval '7d 4h');

  -- DELTA RAVENS (NA West 02–07 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000004', a + interval '1d 2h',      a + interval '1d 7h'),
    ('00000000-0000-0000-1000-000000000004', a + interval '2d 2h 30m',  a + interval '2d 7h'),
    ('00000000-0000-0000-1000-000000000004', a + interval '3d 2h',      a + interval '3d 6h 30m'),
    ('00000000-0000-0000-1000-000000000004', a + interval '4d 2h',      a + interval '4d 7h'),
    ('00000000-0000-0000-1000-000000000004', a + interval '5d 2h',      a + interval '5d 7h'),
    ('00000000-0000-0000-2000-000000000010', a + interval '1d 2h 30m',  a + interval '1d 7h'),
    ('00000000-0000-0000-2000-000000000010', a + interval '2d 2h',      a + interval '2d 6h 30m'),
    ('00000000-0000-0000-2000-000000000010', a + interval '3d 2h',      a + interval '3d 7h'),
    ('00000000-0000-0000-2000-000000000010', a + interval '4d 2h 30m',  a + interval '4d 7h'),
    ('00000000-0000-0000-2000-000000000010', a + interval '5d 2h',      a + interval '5d 6h 30m'),
    ('00000000-0000-0000-2000-000000000011', a + interval '1d 2h',      a + interval '1d 6h 30m'),
    ('00000000-0000-0000-2000-000000000011', a + interval '2d 2h 30m',  a + interval '2d 7h'),
    ('00000000-0000-0000-2000-000000000011', a + interval '3d 2h 30m',  a + interval '3d 6h 30m'),
    ('00000000-0000-0000-2000-000000000011', a + interval '5d 2h',      a + interval '5d 7h'),
    ('00000000-0000-0000-2000-000000000011', a + interval '6d 2h',      a + interval '6d 6h 30m'),
    ('00000000-0000-0000-2000-000000000012', a + interval '1d 2h 30m',  a + interval '1d 7h'),
    ('00000000-0000-0000-2000-000000000012', a + interval '3d 2h',      a + interval '3d 7h'),
    ('00000000-0000-0000-2000-000000000012', a + interval '4d 2h',      a + interval '4d 6h 30m'),
    ('00000000-0000-0000-2000-000000000012', a + interval '5d 2h 30m',  a + interval '5d 7h'),
    ('00000000-0000-0000-2000-000000000012', a + interval '6d 2h 30m',  a + interval '6d 7h');

  -- ECHO STORM (Crossover 19–01 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000005', a + interval '0d 19h 30m', a + interval '1d 1h'),
    ('00000000-0000-0000-1000-000000000005', a + interval '2d 19h',     a + interval '3d 0h'),
    ('00000000-0000-0000-1000-000000000005', a + interval '3d 20h',     a + interval '4d 1h'),
    ('00000000-0000-0000-1000-000000000005', a + interval '4d 19h',     a + interval '5d 1h'),
    ('00000000-0000-0000-1000-000000000005', a + interval '5d 19h',     a + interval '6d 0h 30m'),
    ('00000000-0000-0000-2000-000000000013', a + interval '0d 20h',     a + interval '1d 1h'),
    ('00000000-0000-0000-2000-000000000013', a + interval '2d 19h 30m', a + interval '3d 0h'),
    ('00000000-0000-0000-2000-000000000013', a + interval '3d 19h 30m', a + interval '4d 0h 30m'),
    ('00000000-0000-0000-2000-000000000013', a + interval '4d 19h 30m', a + interval '5d 1h'),
    ('00000000-0000-0000-2000-000000000013', a + interval '5d 19h 30m', a + interval '6d 1h'),
    ('00000000-0000-0000-2000-000000000014', a + interval '0d 19h 30m', a + interval '1d 0h 30m'),
    ('00000000-0000-0000-2000-000000000014', a + interval '2d 19h',     a + interval '2d 23h 30m'),
    ('00000000-0000-0000-2000-000000000014', a + interval '4d 19h',     a + interval '5d 0h 30m'),
    ('00000000-0000-0000-2000-000000000014', a + interval '5d 19h',     a + interval '6d 0h'),
    ('00000000-0000-0000-2000-000000000014', a + interval '6d 20h',     a + interval '7d 1h'),
    ('00000000-0000-0000-2000-000000000015', a + interval '0d 20h',     a + interval '1d 0h 30m'),
    ('00000000-0000-0000-2000-000000000015', a + interval '2d 19h 30m', a + interval '3d 0h'),
    ('00000000-0000-0000-2000-000000000015', a + interval '3d 20h',     a + interval '4d 0h 30m'),
    ('00000000-0000-0000-2000-000000000015', a + interval '4d 20h',     a + interval '5d 1h'),
    ('00000000-0000-0000-2000-000000000015', a + interval '5d 19h 30m', a + interval '6d 0h 30m');

  -- FOXTROT VIPERS (APAC 08–15 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000006', a + interval '0d 8h',      a + interval '0d 13h'),
    ('00000000-0000-0000-1000-000000000006', a + interval '1d 9h',      a + interval '1d 14h'),
    ('00000000-0000-0000-1000-000000000006', a + interval '3d 8h 30m',  a + interval '3d 14h'),
    ('00000000-0000-0000-1000-000000000006', a + interval '5d 8h',      a + interval '5d 13h'),
    ('00000000-0000-0000-1000-000000000006', a + interval '6d 8h',      a + interval '6d 13h'),
    ('00000000-0000-0000-2000-000000000016', a + interval '0d 8h 30m',  a + interval '0d 13h 30m'),
    ('00000000-0000-0000-2000-000000000016', a + interval '1d 9h',      a + interval '1d 14h'),
    ('00000000-0000-0000-2000-000000000016', a + interval '3d 9h',      a + interval '3d 14h 30m'),
    ('00000000-0000-0000-2000-000000000016', a + interval '5d 8h 30m',  a + interval '5d 13h 30m'),
    ('00000000-0000-0000-2000-000000000016', a + interval '6d 8h',      a + interval '6d 12h 30m'),
    ('00000000-0000-0000-2000-000000000017', a + interval '1d 8h 30m',  a + interval '1d 13h 30m'),
    ('00000000-0000-0000-2000-000000000017', a + interval '2d 9h',      a + interval '2d 14h'),
    ('00000000-0000-0000-2000-000000000017', a + interval '3d 8h',      a + interval '3d 13h'),
    ('00000000-0000-0000-2000-000000000017', a + interval '5d 9h',      a + interval '5d 14h'),
    ('00000000-0000-0000-2000-000000000017', a + interval '6d 8h 30m',  a + interval '6d 13h 30m'),
    ('00000000-0000-0000-2000-000000000018', a + interval '0d 9h',      a + interval '0d 14h'),
    ('00000000-0000-0000-2000-000000000018', a + interval '1d 8h',      a + interval '1d 13h'),
    ('00000000-0000-0000-2000-000000000018', a + interval '3d 9h',      a + interval '3d 14h'),
    ('00000000-0000-0000-2000-000000000018', a + interval '5d 8h',      a + interval '5d 12h 30m'),
    ('00000000-0000-0000-2000-000000000018', a + interval '6d 9h',      a + interval '6d 14h');

  -- GOLF TITANS (EU Central 17–22:30 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000007', a + interval '0d 17h',     a + interval '0d 22h'),
    ('00000000-0000-0000-1000-000000000007', a + interval '2d 17h',     a + interval '2d 22h 30m'),
    ('00000000-0000-0000-1000-000000000007', a + interval '3d 17h 30m', a + interval '3d 22h'),
    ('00000000-0000-0000-1000-000000000007', a + interval '4d 17h',     a + interval '4d 22h 30m'),
    ('00000000-0000-0000-1000-000000000007', a + interval '5d 16h 30m', a + interval '5d 22h'),
    ('00000000-0000-0000-2000-000000000019', a + interval '0d 17h 30m', a + interval '0d 22h'),
    ('00000000-0000-0000-2000-000000000019', a + interval '2d 17h 30m', a + interval '2d 22h 30m'),
    ('00000000-0000-0000-2000-000000000019', a + interval '3d 17h',     a + interval '3d 22h'),
    ('00000000-0000-0000-2000-000000000019', a + interval '4d 17h',     a + interval '4d 22h'),
    ('00000000-0000-0000-2000-000000000019', a + interval '5d 17h',     a + interval '5d 22h'),
    ('00000000-0000-0000-2000-000000000020', a + interval '0d 17h',     a + interval '0d 21h 30m'),
    ('00000000-0000-0000-2000-000000000020', a + interval '2d 17h',     a + interval '2d 22h'),
    ('00000000-0000-0000-2000-000000000020', a + interval '4d 17h 30m', a + interval '4d 22h 30m'),
    ('00000000-0000-0000-2000-000000000020', a + interval '5d 16h 30m', a + interval '5d 21h 30m'),
    ('00000000-0000-0000-2000-000000000020', a + interval '6d 17h',     a + interval '6d 22h'),
    ('00000000-0000-0000-2000-000000000021', a + interval '1d 17h 30m', a + interval '1d 22h 30m'),
    ('00000000-0000-0000-2000-000000000021', a + interval '2d 17h 30m', a + interval '2d 22h'),
    ('00000000-0000-0000-2000-000000000021', a + interval '3d 17h',     a + interval '3d 22h'),
    ('00000000-0000-0000-2000-000000000021', a + interval '4d 17h',     a + interval '4d 22h'),
    ('00000000-0000-0000-2000-000000000021', a + interval '5d 17h',     a + interval '5d 22h');

  -- HOTEL PHANTOMS (NA East 23–04:30 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000008', a + interval '0d 23h',     a + interval '1d 4h'),
    ('00000000-0000-0000-1000-000000000008', a + interval '1d 23h 30m', a + interval '2d 4h'),
    ('00000000-0000-0000-1000-000000000008', a + interval '2d 23h',     a + interval '3d 4h'),
    ('00000000-0000-0000-1000-000000000008', a + interval '4d 23h',     a + interval '5d 4h 30m'),
    ('00000000-0000-0000-1000-000000000008', a + interval '5d 22h 30m', a + interval '6d 4h'),
    ('00000000-0000-0000-2000-000000000022', a + interval '0d 23h 30m', a + interval '1d 4h'),
    ('00000000-0000-0000-2000-000000000022', a + interval '2d 23h',     a + interval '3d 3h 30m'),
    ('00000000-0000-0000-2000-000000000022', a + interval '4d 23h',     a + interval '5d 4h'),
    ('00000000-0000-0000-2000-000000000022', a + interval '5d 23h',     a + interval '6d 4h'),
    ('00000000-0000-0000-2000-000000000022', a + interval '6d 23h',     a + interval '7d 4h'),
    ('00000000-0000-0000-2000-000000000023', a + interval '1d 23h',     a + interval '2d 3h 30m'),
    ('00000000-0000-0000-2000-000000000023', a + interval '2d 23h 30m', a + interval '3d 4h'),
    ('00000000-0000-0000-2000-000000000023', a + interval '3d 23h',     a + interval '4d 4h'),
    ('00000000-0000-0000-2000-000000000023', a + interval '4d 23h 30m', a + interval '5d 4h 30m'),
    ('00000000-0000-0000-2000-000000000023', a + interval '5d 23h',     a + interval '6d 4h'),
    ('00000000-0000-0000-2000-000000000024', a + interval '0d 23h',     a + interval '1d 3h 30m'),
    ('00000000-0000-0000-2000-000000000024', a + interval '2d 23h',     a + interval '3d 4h'),
    ('00000000-0000-0000-2000-000000000024', a + interval '4d 23h',     a + interval '5d 4h'),
    ('00000000-0000-0000-2000-000000000024', a + interval '5d 22h 30m', a + interval '6d 3h 30m'),
    ('00000000-0000-0000-2000-000000000024', a + interval '6d 23h 30m', a + interval '7d 4h');

  -- INDIA REAPERS (NA West 02–07 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000009', a + interval '0d 2h 30m',  a + interval '0d 7h'),
    ('00000000-0000-0000-1000-000000000009', a + interval '2d 2h',      a + interval '2d 7h'),
    ('00000000-0000-0000-1000-000000000009', a + interval '4d 2h',      a + interval '4d 7h'),
    ('00000000-0000-0000-1000-000000000009', a + interval '5d 2h',      a + interval '5d 6h 30m'),
    ('00000000-0000-0000-1000-000000000009', a + interval '6d 2h 30m',  a + interval '6d 7h'),
    ('00000000-0000-0000-2000-000000000025', a + interval '0d 2h',      a + interval '0d 6h 30m'),
    ('00000000-0000-0000-2000-000000000025', a + interval '2d 2h 30m',  a + interval '2d 7h'),
    ('00000000-0000-0000-2000-000000000025', a + interval '3d 2h',      a + interval '3d 6h 30m'),
    ('00000000-0000-0000-2000-000000000025', a + interval '4d 2h 30m',  a + interval '4d 7h'),
    ('00000000-0000-0000-2000-000000000025', a + interval '5d 2h 30m',  a + interval '5d 7h'),
    ('00000000-0000-0000-2000-000000000026', a + interval '1d 2h',      a + interval '1d 7h'),
    ('00000000-0000-0000-2000-000000000026', a + interval '2d 2h',      a + interval '2d 6h 30m'),
    ('00000000-0000-0000-2000-000000000026', a + interval '4d 2h',      a + interval '4d 6h 30m'),
    ('00000000-0000-0000-2000-000000000026', a + interval '5d 2h',      a + interval '5d 7h'),
    ('00000000-0000-0000-2000-000000000026', a + interval '6d 2h',      a + interval '6d 6h 30m'),
    ('00000000-0000-0000-2000-000000000027', a + interval '0d 3h',      a + interval '0d 7h'),
    ('00000000-0000-0000-2000-000000000027', a + interval '2d 2h 30m',  a + interval '2d 7h'),
    ('00000000-0000-0000-2000-000000000027', a + interval '3d 2h 30m',  a + interval '3d 7h'),
    ('00000000-0000-0000-2000-000000000027', a + interval '4d 2h',      a + interval '4d 7h'),
    ('00000000-0000-0000-2000-000000000027', a + interval '6d 2h',      a + interval '6d 7h');

  -- JULIET SPECTERS (Crossover 19–01:30 UTC)
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-1000-000000000010', a + interval '1d 19h 30m', a + interval '2d 1h'),
    ('00000000-0000-0000-1000-000000000010', a + interval '2d 20h',     a + interval '3d 1h'),
    ('00000000-0000-0000-1000-000000000010', a + interval '3d 19h 30m', a + interval '4d 0h 30m'),
    ('00000000-0000-0000-1000-000000000010', a + interval '5d 19h',     a + interval '6d 1h'),
    ('00000000-0000-0000-1000-000000000010', a + interval '6d 20h',     a + interval '7d 1h 30m'),
    ('00000000-0000-0000-2000-000000000028', a + interval '1d 20h',     a + interval '2d 1h 30m'),
    ('00000000-0000-0000-2000-000000000028', a + interval '2d 19h 30m', a + interval '3d 0h 30m'),
    ('00000000-0000-0000-2000-000000000028', a + interval '3d 20h',     a + interval '4d 1h'),
    ('00000000-0000-0000-2000-000000000028', a + interval '5d 19h 30m', a + interval '6d 1h'),
    ('00000000-0000-0000-2000-000000000028', a + interval '6d 19h 30m', a + interval '7d 1h'),
    ('00000000-0000-0000-2000-000000000029', a + interval '1d 19h 30m', a + interval '2d 0h 30m'),
    ('00000000-0000-0000-2000-000000000029', a + interval '3d 19h 30m', a + interval '4d 1h'),
    ('00000000-0000-0000-2000-000000000029', a + interval '4d 20h',     a + interval '5d 1h'),
    ('00000000-0000-0000-2000-000000000029', a + interval '5d 20h',     a + interval '6d 1h 30m'),
    ('00000000-0000-0000-2000-000000000029', a + interval '6d 19h 30m', a + interval '7d 0h 30m'),
    ('00000000-0000-0000-2000-000000000030', a + interval '1d 20h',     a + interval '2d 1h'),
    ('00000000-0000-0000-2000-000000000030', a + interval '2d 20h',     a + interval '3d 1h'),
    ('00000000-0000-0000-2000-000000000030', a + interval '4d 19h 30m', a + interval '5d 0h 30m'),
    ('00000000-0000-0000-2000-000000000030', a + interval '5d 19h 30m', a + interval '6d 1h 30m'),
    ('00000000-0000-0000-2000-000000000030', a + interval '6d 20h',     a + interval '7d 1h');

  -- FILLERS
  insert into public.availabilities (user_id, starts_at, ends_at) values
    ('00000000-0000-0000-4000-000000000001', a + interval '0d 18h',     a + interval '0d 23h'),
    ('00000000-0000-0000-4000-000000000001', a + interval '2d 18h',     a + interval '2d 23h'),
    ('00000000-0000-0000-4000-000000000001', a + interval '4d 19h',     a + interval '5d 0h'),
    ('00000000-0000-0000-4000-000000000001', a + interval '5d 17h',     a + interval '5d 23h'),
    ('00000000-0000-0000-4000-000000000002', a + interval '1d 23h',     a + interval '2d 4h'),
    ('00000000-0000-0000-4000-000000000002', a + interval '3d 23h',     a + interval '4d 4h'),
    ('00000000-0000-0000-4000-000000000002', a + interval '5d 22h',     a + interval '6d 4h');
end $$;

-- ── Demo scrims ────────────────────────────────────────────
do $$
declare
  a  date := date_trunc('week', CURRENT_DATE + interval '7 days')::date;
  pa date := date_trunc('week', CURRENT_DATE - interval '7 days')::date;
begin
  insert into public.scrims (id, organizer_id, starts_at, status, created_at) values
    ('00000000-0000-0000-5000-000000000001', '00000000-0000-0000-1000-000000000001',
     pa + interval '2d 18h', 'confirmed', pa + interval '0d 10h'),
    ('00000000-0000-0000-5000-000000000002', '00000000-0000-0000-1000-000000000003',
     pa + interval '5d 23h', 'confirmed', pa + interval '2d 14h'),
    ('00000000-0000-0000-5000-000000000003', '00000000-0000-0000-1000-000000000001',
     a + interval '2d 18h', 'confirmed', a - interval '2d'),
    ('00000000-0000-0000-5000-000000000004', '00000000-0000-0000-1000-000000000007',
     a + interval '4d 19h', 'confirmed', a - interval '1d'),
    ('00000000-0000-0000-5000-000000000005', '00000000-0000-0000-1000-000000000003',
     a + interval '5d 23h', 'confirmed', a - interval '1d'),
    ('00000000-0000-0000-5000-000000000006', '00000000-0000-0000-1000-000000000005',
     a + interval '0d 20h', 'proposed',  a - interval '3d'),
    ('00000000-0000-0000-5000-000000000007', '00000000-0000-0000-1000-000000000004',
     a + interval '3d 3h',  'proposed',  a - interval '2d'),
    ('00000000-0000-0000-5000-000000000008', '00000000-0000-0000-1000-000000000010',
     a + interval '5d 19h', 'cancelled', a - interval '4d')
  on conflict (id) do nothing;

  insert into public.scrim_teams (scrim_id, team_id) values
    ('00000000-0000-0000-5000-000000000001', '00000000-0000-0000-3000-000000000001'),
    ('00000000-0000-0000-5000-000000000001', '00000000-0000-0000-3000-000000000007'),
    ('00000000-0000-0000-5000-000000000002', '00000000-0000-0000-3000-000000000003'),
    ('00000000-0000-0000-5000-000000000002', '00000000-0000-0000-3000-000000000008'),
    ('00000000-0000-0000-5000-000000000003', '00000000-0000-0000-3000-000000000001'),
    ('00000000-0000-0000-5000-000000000003', '00000000-0000-0000-3000-000000000002'),
    ('00000000-0000-0000-5000-000000000004', '00000000-0000-0000-3000-000000000007'),
    ('00000000-0000-0000-5000-000000000004', '00000000-0000-0000-3000-000000000005'),
    ('00000000-0000-0000-5000-000000000005', '00000000-0000-0000-3000-000000000003'),
    ('00000000-0000-0000-5000-000000000005', '00000000-0000-0000-3000-000000000008'),
    ('00000000-0000-0000-5000-000000000006', '00000000-0000-0000-3000-000000000001'),
    ('00000000-0000-0000-5000-000000000006', '00000000-0000-0000-3000-000000000005'),
    ('00000000-0000-0000-5000-000000000007', '00000000-0000-0000-3000-000000000004'),
    ('00000000-0000-0000-5000-000000000007', '00000000-0000-0000-3000-000000000009'),
    ('00000000-0000-0000-5000-000000000008', '00000000-0000-0000-3000-000000000010'),
    ('00000000-0000-0000-5000-000000000008', '00000000-0000-0000-3000-000000000007')
  on conflict do nothing;
end $$;
