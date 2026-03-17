-- ============================================================
-- Dev seed data — expanded demo accounts
--
-- Admin:   admin@dev.local  / admin1234
-- Leaders: demo-<team>-lead@dev.local     / test1234
-- Players: demo-<team>-<role>@dev.local   / test1234
-- Fillers: demo-filler-<n>@dev.local      / test1234
--
-- 25 teams × 4 players (1 leader + 3 members)
-- 12 filler players (no team)
-- 5 availability windows per player (procedurally generated)
-- 12 scrims (3 past confirmed, 5 upcoming confirmed,
--            3 proposed, 1 cancelled)
--
-- Anchor = Monday of the week after seed date
-- Past anchor = Monday of the week before seed date
--
-- Teams by region:
--   EU (8):        Alpha Wolves, Bravo Hawks, Golf Titans,
--                  Kilo Sentinels, Lima Crusaders, Mike Wardens,
--                  November Ghosts, Oscar Falcons
--   NA East (6):   Charlie Foxes, Hotel Phantoms, Papa Sabres,
--                  Quebec Strikers, Romeo Lancers, Sierra Hunters
--   NA West (5):   Delta Ravens, India Reapers, Tango Wolves,
--                  Uniform Cobras, Victor Blades
--   Crossover (3): Echo Storm, Juliet Specters, Whiskey Shadows
--   APAC (3):      Foxtrot Vipers, X-ray Dragons, Yankee Ronin
--
-- Key availability windows (UTC):
--   EU evening:      16:30–22:30
--   NA East evening: 23:00–04:00
--   NA West evening: 02:00–07:00
--   Crossover:       19:00–01:00 (EU late + NA East afternoon)
--   APAC:            08:00–14:00
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

-- ── Clean up demo data from migrations ───────────────────────
delete from public.scrim_teams
where scrim_id in (
  select id from public.scrims
  where organizer_id in (select id from auth.users where email like 'demo-%@dev.local')
);
delete from public.scrims
where organizer_id in (select id from auth.users where email like 'demo-%@dev.local');
delete from public.availabilities
where user_id in (select id from auth.users where email like 'demo-%@dev.local');
delete from public.team_members
where team_id in (
  select id from public.teams
  where leader_id in (select id from auth.users where email like 'demo-%@dev.local')
);
delete from public.teams
where leader_id in (select id from auth.users where email like 'demo-%@dev.local');
delete from public.profiles
where id in (select id from auth.users where email like 'demo-%@dev.local');
delete from auth.identities
where user_id in (select id from auth.users where email like 'demo-%@dev.local');
delete from auth.users
where email like 'demo-%@dev.local';

-- ── Temp function: generate 5 availability windows per user ──
create or replace function pg_temp.gen_avail(
  p_uid uuid,
  p_anchor date,
  p_start_min int,
  p_end_min int,
  p_idx int
) returns void language plpgsql as $fn$
declare
  d int;
  skip1 int := p_idx % 7;
  skip2 int := (p_idx + 3) % 7;
  sm int;
  em int;
begin
  for d in 0..6 loop
    if d = skip1 or d = skip2 then continue; end if;

    sm := p_start_min + ((p_idx * 17 + d * 7) % 4) * 15;
    em := p_end_min   - ((p_idx * 13 + d * 11) % 3) * 15;

    if em - sm >= 180 then
      insert into public.availabilities (user_id, starts_at, ends_at)
      values (
        p_uid,
        p_anchor + make_interval(days := d, mins := sm),
        p_anchor + make_interval(days := d, mins := em)
      );
    end if;
  end loop;
end;
$fn$;

-- ── Demo players (25 leaders + 75 players + 12 fillers) ──────
do $$
declare
  team_codes text[] := array[
    'alpha','bravo','charlie','delta','echo','foxtrot',
    'golf','hotel','india','juliet','kilo','lima','mike',
    'november','oscar','papa','quebec','romeo','sierra',
    'tango','uniform','victor','whiskey','xray','yankee'
  ];
  team_names text[] := array[
    'Demo Alpha Wolves',    'Demo Bravo Hawks',      'Demo Charlie Foxes',
    'Demo Delta Ravens',    'Demo Echo Storm',       'Demo Foxtrot Vipers',
    'Demo Golf Titans',     'Demo Hotel Phantoms',   'Demo India Reapers',
    'Demo Juliet Specters', 'Demo Kilo Sentinels',   'Demo Lima Crusaders',
    'Demo Mike Wardens',    'Demo November Ghosts',  'Demo Oscar Falcons',
    'Demo Papa Sabres',     'Demo Quebec Strikers',  'Demo Romeo Lancers',
    'Demo Sierra Hunters',  'Demo Tango Wolves',     'Demo Uniform Cobras',
    'Demo Victor Blades',   'Demo Whiskey Shadows',  'Demo X-ray Dragons',
    'Demo Yankee Ronin'
  ];
  team_regions int[] := array[
    1, 1, 2, 3, 4, 5, 1, 2, 3, 4,
    1, 1, 1, 1, 1, 2, 2, 2, 2, 3,
    3, 3, 4, 5, 5
  ];
  region_start int[] := array[990, 1380, 120, 1140, 480];
  region_end   int[] := array[1350, 1680, 420, 1500, 840];

  role_suffixes text[] := array['rifle','sniper','support'];
  tok_suffixes  text[] := array['r','s','u'];

  usernames text[] := array[
    -- Leaders (25)
    'demo-AlphaWolf',     'demo-HawkEye',       'demo-FoxHound',
    'demo-RavenClaw',     'demo-StormRider',     'demo-ViperFang',
    'demo-TitanForce',    'demo-PhantomX',       'demo-ReaperMain',
    'demo-SpecterOps',    'demo-IronValor',      'demo-BladeDancer',
    'demo-WarPilot',      'demo-FrostKnight',    'demo-DawnBreaker',
    'demo-ThunderStrike', 'demo-HexBolt',        'demo-NightFury',
    'demo-AcidRain',      'demo-SkyBurn',        'demo-VoltEdge',
    'demo-DustDevil',     'demo-TwilightOps',    'demo-JadeStorm',
    'demo-SamuraiX',
    -- T1 Alpha
    'demo-RazorAim',      'demo-GhostShot',      'demo-IronSights',
    -- T2 Bravo
    'demo-BlazeRush',     'demo-StormBreak',     'demo-NightOwl',
    -- T3 Charlie
    'demo-ViperStrike',   'demo-ThunderClap',    'demo-ShadowStep',
    -- T4 Delta
    'demo-FrostBite',     'demo-DeadEye',        'demo-SteelNerve',
    -- T5 Echo
    'demo-PhantomAce',    'demo-NeonBlade',      'demo-CyberPulse',
    -- T6 Foxtrot
    'demo-DragonFire',    'demo-TigerClaw',      'demo-SilentWind',
    -- T7 Golf
    'demo-CrushMode',     'demo-WarHammer',      'demo-IronWill',
    -- T8 Hotel
    'demo-DarkMatter',    'demo-VoidWalker',     'demo-NullPoint',
    -- T9 India
    'demo-SoulHarvest',   'demo-GrimShade',      'demo-BoneCrush',
    -- T10 Juliet
    'demo-GhostProto',    'demo-ShadowOps',      'demo-MidnightRun',
    -- T11 Kilo
    'demo-RazorWire',     'demo-SharpEdge',      'demo-ColdSteel',
    -- T12 Lima
    'demo-FireBrand',     'demo-EmberGlow',      'demo-AshStorm',
    -- T13 Mike
    'demo-StealthBomb',   'demo-SilentOps',      'demo-CovertHit',
    -- T14 November
    'demo-NorthWind',     'demo-BlizzKing',      'demo-ArcticFox',
    -- T15 Oscar
    'demo-SunRise',       'demo-GoldEagle',      'demo-BrightStar',
    -- T16 Papa
    'demo-MapleBlade',    'demo-FrostEdge',      'demo-NorthStar',
    -- T17 Quebec
    'demo-WindRunner',    'demo-StormChase',     'demo-CloudNine',
    -- T18 Romeo
    'demo-NightRaven',    'demo-DarkKnight',     'demo-ShadowBlade',
    -- T19 Sierra
    'demo-LionHeart',    'demo-PeakForce',      'demo-RidgeRun',
    -- T20 Tango
    'demo-SunsetBlaze',  'demo-DuskRider',      'demo-TwiSnipe',
    -- T21 Uniform
    'demo-RainMaker',    'demo-ThunderBolt',    'demo-LightRod',
    -- T22 Victor
    'demo-DesertHawk',   'demo-SandStorm',      'demo-MirageShot',
    -- T23 Whiskey
    'demo-NightShift',   'demo-DarkHorse',      'demo-GhostRun',
    -- T24 X-ray
    'demo-DragonEye',    'demo-PantherClaw',    'demo-CobraKing',
    -- T25 Yankee
    'demo-RooJack',      'demo-OutbackAce',     'demo-DownUnder',
    -- Fillers (12)
    'demo-LoneStar',     'demo-RogueAgent',     'demo-FreeLancer',
    'demo-WildCard',     'demo-Ronin77',        'demo-Nomad66',
    'demo-DrifterX',     'demo-MercHire',       'demo-OzGunner',
    'demo-EuroSub',      'demo-MapleGhost',     'demo-TigerSub'
  ];

  timezones text[] := array[
    -- Leaders (25)
    'Europe/Paris',          'Europe/Warsaw',         'America/New_York',
    'America/Los_Angeles',   'Europe/London',         'Asia/Tokyo',
    'Europe/Berlin',         'America/New_York',      'America/Denver',
    'Europe/London',         'Europe/London',         'Europe/Madrid',
    'Europe/Amsterdam',      'Europe/Stockholm',      'Europe/Bucharest',
    'America/Toronto',       'America/Chicago',       'America/New_York',
    'America/Toronto',       'America/Los_Angeles',   'America/Vancouver',
    'America/Phoenix',       'America/New_York',      'Asia/Singapore',
    'Australia/Sydney',
    -- T1 Alpha (EU)
    'Europe/Berlin',         'Europe/London',         'Europe/Paris',
    -- T2 Bravo (EU)
    'Europe/Warsaw',         'Europe/Madrid',         'Europe/Bucharest',
    -- T3 Charlie (NA East)
    'America/Toronto',       'America/Chicago',       'America/New_York',
    -- T4 Delta (NA West)
    'America/Denver',        'America/Vancouver',     'America/Los_Angeles',
    -- T5 Echo (Crossover)
    'America/New_York',      'Europe/Berlin',         'Europe/London',
    -- T6 Foxtrot (APAC)
    'Asia/Singapore',        'Australia/Sydney',      'Asia/Tokyo',
    -- T7 Golf (EU)
    'Europe/Amsterdam',      'Europe/Stockholm',      'Europe/Berlin',
    -- T8 Hotel (NA East)
    'America/New_York',      'America/Toronto',       'America/Chicago',
    -- T9 India (NA West)
    'America/Denver',        'America/Phoenix',       'America/Los_Angeles',
    -- T10 Juliet (Crossover)
    'Europe/Dublin',         'America/Toronto',       'Europe/London',
    -- T11 Kilo (EU)
    'Europe/Paris',          'Europe/Berlin',         'Europe/London',
    -- T12 Lima (EU)
    'Europe/Madrid',         'Europe/Lisbon',         'Europe/Paris',
    -- T13 Mike (EU)
    'Europe/Amsterdam',      'Europe/Brussels',       'Europe/Berlin',
    -- T14 November (EU)
    'Europe/Stockholm',      'Europe/Helsinki',       'Europe/Oslo',
    -- T15 Oscar (EU)
    'Europe/Bucharest',      'Europe/Athens',         'Europe/Sofia',
    -- T16 Papa (NA East)
    'America/Toronto',       'America/New_York',      'America/Detroit',
    -- T17 Quebec (NA East)
    'America/Chicago',       'America/New_York',      'America/Toronto',
    -- T18 Romeo (NA East)
    'America/New_York',      'America/Toronto',       'America/Chicago',
    -- T19 Sierra (NA East)
    'America/Toronto',       'America/New_York',      'America/Chicago',
    -- T20 Tango (NA West)
    'America/Los_Angeles',   'America/Denver',        'America/Vancouver',
    -- T21 Uniform (NA West)
    'America/Vancouver',     'America/Los_Angeles',   'America/Denver',
    -- T22 Victor (NA West)
    'America/Phoenix',       'America/Denver',        'America/Los_Angeles',
    -- T23 Whiskey (Crossover)
    'America/New_York',      'Europe/London',         'America/Toronto',
    -- T24 X-ray (APAC)
    'Asia/Singapore',        'Asia/Tokyo',            'Asia/Manila',
    -- T25 Yankee (APAC)
    'Australia/Sydney',      'Australia/Melbourne',   'Australia/Brisbane',
    -- Fillers (12)
    'Europe/Paris',          'America/New_York',      'Europe/Berlin',
    'America/Los_Angeles',   'Asia/Tokyo',            'America/Chicago',
    'Europe/London',         'America/Denver',        'Australia/Sydney',
    'Europe/Warsaw',         'America/Toronto',       'Asia/Singapore'
  ];

  filler_regions int[] := array[1, 2, 1, 3, 5, 2, 1, 3, 5, 1, 2, 5];

  uid uuid;
  v_email text;
  v_role text;
  team_idx int;
  role_idx int;
  region int;
  a date := date_trunc('week', CURRENT_DATE + interval '7 days')::date;
  i int;
  j int;
begin
  -- ── Insert 112 auth users ──────────────────────────────────
  for i in 1..112 loop
    if i <= 25 then
      uid     := ('00000000-0000-0000-1000-' || lpad(i::text, 12, '0'))::uuid;
      v_email := 'demo-' || team_codes[i] || '-lead@dev.local';
      v_role  := 'leader';
    elsif i <= 100 then
      team_idx := ((i - 26) / 3) + 1;
      role_idx := ((i - 26) % 3) + 1;
      uid     := ('00000000-0000-0000-2000-' || lpad((i - 25)::text, 12, '0'))::uuid;
      v_email := 'demo-' || team_codes[team_idx] || '-' || role_suffixes[role_idx] || '@dev.local';
      v_role  := 'player';
    else
      uid     := ('00000000-0000-0000-4000-' || lpad((i - 100)::text, 12, '0'))::uuid;
      v_email := 'demo-filler-' || (i - 100)::text || '@dev.local';
      v_role  := 'filler';
    end if;

    insert into auth.users (
      id, instance_id, aud, role,
      email, encrypted_password, email_confirmed_at,
      confirmation_token, recovery_token, email_change_token_new,
      email_change, email_change_token_current,
      raw_app_meta_data, raw_user_meta_data,
      is_super_admin, is_sso_user, is_anonymous,
      created_at, updated_at
    ) values (
      uid,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      v_email,
      extensions.crypt('test1234', extensions.gen_salt('bf', 10)),
      now(),
      '', '', '', '', '',
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      jsonb_build_object('username', usernames[i], 'role', v_role, 'timezone', timezones[i]),
      false, false, false,
      now(), now()
    ) on conflict (id) do nothing;

    insert into auth.identities (
      user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) values (
      uid, v_email, 'email',
      jsonb_build_object('sub', uid::text, 'email', v_email),
      now(), now(), now()
    ) on conflict (provider_id, provider) do nothing;
  end loop;

  -- ── Fix week_starts_on for NA-timezone users ───────────────
  update public.profiles
  set week_starts_on = 'sunday'
  where timezone like 'America/%'
    and id in (select id from auth.users where email like 'demo-%@dev.local');

  -- ── Insert 25 teams ────────────────────────────────────────
  for i in 1..25 loop
    insert into public.teams (id, name, leader_id) values (
      ('00000000-0000-0000-3000-' || lpad(i::text, 12, '0'))::uuid,
      team_names[i],
      ('00000000-0000-0000-1000-' || lpad(i::text, 12, '0'))::uuid
    ) on conflict (id) do nothing;
  end loop;

  -- ── Insert 75 team members (3 per team) ────────────────────
  for i in 1..25 loop
    for j in 1..3 loop
      insert into public.team_members (team_id, user_id, invite_email, invite_token, status, activated_at)
      values (
        ('00000000-0000-0000-3000-' || lpad(i::text, 12, '0'))::uuid,
        ('00000000-0000-0000-2000-' || lpad(((i - 1) * 3 + j)::text, 12, '0'))::uuid,
        'demo-' || team_codes[i] || '-' || role_suffixes[j] || '@dev.local',
        'tok-' || substr(team_codes[i], 1, 3) || '-' || tok_suffixes[j],
        'active',
        now()
      ) on conflict do nothing;
    end loop;
  end loop;

  -- ── Generate availability for all 112 users ────────────────
  for i in 1..112 loop
    if i <= 25 then
      uid    := ('00000000-0000-0000-1000-' || lpad(i::text, 12, '0'))::uuid;
      region := team_regions[i];
    elsif i <= 100 then
      uid      := ('00000000-0000-0000-2000-' || lpad((i - 25)::text, 12, '0'))::uuid;
      team_idx := ((i - 26) / 3) + 1;
      region   := team_regions[team_idx];
    else
      uid    := ('00000000-0000-0000-4000-' || lpad((i - 100)::text, 12, '0'))::uuid;
      region := filler_regions[i - 100];
    end if;

    perform pg_temp.gen_avail(uid, a, region_start[region], region_end[region], i);
  end loop;
end $$;

-- ── Demo scrims ──────────────────────────────────────────────
do $$
declare
  a  date := date_trunc('week', CURRENT_DATE + interval '7 days')::date;
  pa date := date_trunc('week', CURRENT_DATE - interval '7 days')::date;
begin
  insert into public.scrims (id, organizer_id, starts_at, status, created_at) values
    -- Past confirmed (3)
    ('00000000-0000-0000-5000-000000000001', '00000000-0000-0000-1000-000000000001',
     pa + interval '2d 18h', 'confirmed', pa + interval '0d 10h'),
    ('00000000-0000-0000-5000-000000000002', '00000000-0000-0000-1000-000000000003',
     pa + interval '5d 23h', 'confirmed', pa + interval '2d 14h'),
    ('00000000-0000-0000-5000-000000000003', '00000000-0000-0000-1000-000000000006',
     pa + interval '3d 9h',  'confirmed', pa + interval '1d 8h'),
    -- Upcoming confirmed (5)
    ('00000000-0000-0000-5000-000000000004', '00000000-0000-0000-1000-000000000001',
     a + interval '2d 18h',  'confirmed', a - interval '2d'),
    ('00000000-0000-0000-5000-000000000005', '00000000-0000-0000-1000-000000000007',
     a + interval '4d 19h',  'confirmed', a - interval '1d'),
    ('00000000-0000-0000-5000-000000000006', '00000000-0000-0000-1000-000000000003',
     a + interval '5d 23h',  'confirmed', a - interval '1d'),
    ('00000000-0000-0000-5000-000000000007', '00000000-0000-0000-1000-000000000011',
     a + interval '3d 17h',  'confirmed', a - interval '1d'),
    ('00000000-0000-0000-5000-000000000008', '00000000-0000-0000-1000-000000000004',
     a + interval '1d 3h',   'confirmed', a - interval '2d'),
    -- Proposed (3)
    ('00000000-0000-0000-5000-000000000009', '00000000-0000-0000-1000-000000000005',
     a + interval '0d 20h',  'proposed',  a - interval '3d'),
    ('00000000-0000-0000-5000-000000000010', '00000000-0000-0000-1000-000000000004',
     a + interval '3d 3h',   'proposed',  a - interval '2d'),
    ('00000000-0000-0000-5000-000000000011', '00000000-0000-0000-1000-000000000016',
     a + interval '4d 23h',  'proposed',  a - interval '1d'),
    -- Cancelled (1)
    ('00000000-0000-0000-5000-000000000012', '00000000-0000-0000-1000-000000000010',
     a + interval '5d 19h',  'cancelled', a - interval '4d')
  on conflict (id) do nothing;

  insert into public.scrim_teams (scrim_id, team_id) values
    -- Past: Alpha vs Golf
    ('00000000-0000-0000-5000-000000000001', '00000000-0000-0000-3000-000000000001'),
    ('00000000-0000-0000-5000-000000000001', '00000000-0000-0000-3000-000000000007'),
    -- Past: Charlie vs Hotel
    ('00000000-0000-0000-5000-000000000002', '00000000-0000-0000-3000-000000000003'),
    ('00000000-0000-0000-5000-000000000002', '00000000-0000-0000-3000-000000000008'),
    -- Past: Foxtrot vs X-ray
    ('00000000-0000-0000-5000-000000000003', '00000000-0000-0000-3000-000000000006'),
    ('00000000-0000-0000-5000-000000000003', '00000000-0000-0000-3000-000000000024'),
    -- Upcoming: Alpha vs Bravo
    ('00000000-0000-0000-5000-000000000004', '00000000-0000-0000-3000-000000000001'),
    ('00000000-0000-0000-5000-000000000004', '00000000-0000-0000-3000-000000000002'),
    -- Upcoming: Golf vs Echo
    ('00000000-0000-0000-5000-000000000005', '00000000-0000-0000-3000-000000000007'),
    ('00000000-0000-0000-5000-000000000005', '00000000-0000-0000-3000-000000000005'),
    -- Upcoming: Charlie vs Hotel
    ('00000000-0000-0000-5000-000000000006', '00000000-0000-0000-3000-000000000003'),
    ('00000000-0000-0000-5000-000000000006', '00000000-0000-0000-3000-000000000008'),
    -- Upcoming: Kilo vs Lima
    ('00000000-0000-0000-5000-000000000007', '00000000-0000-0000-3000-000000000011'),
    ('00000000-0000-0000-5000-000000000007', '00000000-0000-0000-3000-000000000012'),
    -- Upcoming: Delta vs India
    ('00000000-0000-0000-5000-000000000008', '00000000-0000-0000-3000-000000000004'),
    ('00000000-0000-0000-5000-000000000008', '00000000-0000-0000-3000-000000000009'),
    -- Proposed: Echo vs Alpha
    ('00000000-0000-0000-5000-000000000009', '00000000-0000-0000-3000-000000000005'),
    ('00000000-0000-0000-5000-000000000009', '00000000-0000-0000-3000-000000000001'),
    -- Proposed: Delta vs India
    ('00000000-0000-0000-5000-000000000010', '00000000-0000-0000-3000-000000000004'),
    ('00000000-0000-0000-5000-000000000010', '00000000-0000-0000-3000-000000000009'),
    -- Proposed: Papa vs Romeo
    ('00000000-0000-0000-5000-000000000011', '00000000-0000-0000-3000-000000000016'),
    ('00000000-0000-0000-5000-000000000011', '00000000-0000-0000-3000-000000000018'),
    -- Cancelled: Juliet vs Golf
    ('00000000-0000-0000-5000-000000000012', '00000000-0000-0000-3000-000000000010'),
    ('00000000-0000-0000-5000-000000000012', '00000000-0000-0000-3000-000000000007')
  on conflict do nothing;
end $$;
