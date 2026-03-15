-- ============================================================
-- Dev seed data
--
-- Admin:   admin@dev.local  / admin1234
-- Leaders: leader{1-9}@dev.local / test1234
-- Players: player{1-18}@dev.local / test1234
--
-- 9 teams × 3 players (1 leader + 2 members each)
-- All players have availability pre-filled (UTC 17:00–22:00):
--   Group A – Teams 1–3 (Phoenix/Wolves/Falcons): Mon 16, Wed 18, Fri 20 Mar
--   Group B – Teams 4–6 (Ghosts/Thunder/Shadow):  Tue 17, Thu 19, Sat 21 Mar
--   Group C – Teams 7–9 (Arctic/Storm/Hunters):   Wed 18, Fri 20, Sun 22 Mar
--
-- Scrim matchable slots:
--   Wed 18 Mar 17:00 UTC → Groups A + C both free (6 teams)
--   Fri 20 Mar 17:00 UTC → Groups A + C both free (6 teams)
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

-- ── Test players (9 leaders + 18 players) ────────────────────
do $$
declare
  uids uuid[] := array[
    -- Leaders 1–9
    '00000000-0000-0000-1000-000000000001'::uuid,
    '00000000-0000-0000-1000-000000000002'::uuid,
    '00000000-0000-0000-1000-000000000003'::uuid,
    '00000000-0000-0000-1000-000000000004'::uuid,
    '00000000-0000-0000-1000-000000000005'::uuid,
    '00000000-0000-0000-1000-000000000006'::uuid,
    '00000000-0000-0000-1000-000000000007'::uuid,
    '00000000-0000-0000-1000-000000000008'::uuid,
    '00000000-0000-0000-1000-000000000009'::uuid,
    -- Players 1–18
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
    '00000000-0000-0000-2000-000000000018'::uuid
  ];
  emails text[] := array[
    'leader1@dev.local','leader2@dev.local','leader3@dev.local',
    'leader4@dev.local','leader5@dev.local','leader6@dev.local',
    'leader7@dev.local','leader8@dev.local','leader9@dev.local',
    'player1@dev.local', 'player2@dev.local', 'player3@dev.local',
    'player4@dev.local', 'player5@dev.local', 'player6@dev.local',
    'player7@dev.local', 'player8@dev.local', 'player9@dev.local',
    'player10@dev.local','player11@dev.local','player12@dev.local',
    'player13@dev.local','player14@dev.local','player15@dev.local',
    'player16@dev.local','player17@dev.local','player18@dev.local'
  ];
  usernames text[] := array[
    'PhoenixLead','WolvesLead','FalconsLead',
    'GhostsLead','ThunderLead','ShadowLead',
    'ArcticLead','StormLead','HuntersLead',
    'PhoenixAce','PhoenixGun',
    'WolvesAce','WolvesGun',
    'FalconsAce','FalconsGun',
    'GhostsAce','GhostsGun',
    'ThunderAce','ThunderGun',
    'ShadowAce','ShadowGun',
    'ArcticAce','ArcticGun',
    'StormAce','StormGun',
    'HuntersAce','HuntersGun'
  ];
  roles text[] := array[
    'leader','leader','leader','leader','leader','leader','leader','leader','leader',
    'player','player','player','player','player','player','player','player','player',
    'player','player','player','player','player','player','player','player','player'
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
      jsonb_build_object('username', usernames[i], 'role', roles[i]),
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
  ('00000000-0000-0000-3000-000000000001', 'Phoenix Squad',  '00000000-0000-0000-1000-000000000001'),
  ('00000000-0000-0000-3000-000000000002', 'Iron Wolves',    '00000000-0000-0000-1000-000000000002'),
  ('00000000-0000-0000-3000-000000000003', 'Steel Falcons',  '00000000-0000-0000-1000-000000000003'),
  ('00000000-0000-0000-3000-000000000004', 'Ghost Protocol', '00000000-0000-0000-1000-000000000004'),
  ('00000000-0000-0000-3000-000000000005', 'Thunder Ravens', '00000000-0000-0000-1000-000000000005'),
  ('00000000-0000-0000-3000-000000000006', 'Shadow Vipers',  '00000000-0000-0000-1000-000000000006'),
  ('00000000-0000-0000-3000-000000000007', 'Arctic Fox',     '00000000-0000-0000-1000-000000000007'),
  ('00000000-0000-0000-3000-000000000008', 'Delta Storm',    '00000000-0000-0000-1000-000000000008'),
  ('00000000-0000-0000-3000-000000000009', 'Night Hunters',  '00000000-0000-0000-1000-000000000009')
on conflict (id) do nothing;

-- ── Team members (2 active members per team, leader excluded) ─
insert into public.team_members (team_id, user_id, invite_email, invite_token, status, activated_at) values
  -- Team 1: Phoenix Squad
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000001','player1@dev.local', 'tok-t1-p1','active',now()),
  ('00000000-0000-0000-3000-000000000001','00000000-0000-0000-2000-000000000002','player2@dev.local', 'tok-t1-p2','active',now()),
  -- Team 2: Iron Wolves
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000003','player3@dev.local', 'tok-t2-p1','active',now()),
  ('00000000-0000-0000-3000-000000000002','00000000-0000-0000-2000-000000000004','player4@dev.local', 'tok-t2-p2','active',now()),
  -- Team 3: Steel Falcons
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000005','player5@dev.local', 'tok-t3-p1','active',now()),
  ('00000000-0000-0000-3000-000000000003','00000000-0000-0000-2000-000000000006','player6@dev.local', 'tok-t3-p2','active',now()),
  -- Team 4: Ghost Protocol
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000007','player7@dev.local', 'tok-t4-p1','active',now()),
  ('00000000-0000-0000-3000-000000000004','00000000-0000-0000-2000-000000000008','player8@dev.local', 'tok-t4-p2','active',now()),
  -- Team 5: Thunder Ravens
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000009','player9@dev.local', 'tok-t5-p1','active',now()),
  ('00000000-0000-0000-3000-000000000005','00000000-0000-0000-2000-000000000010','player10@dev.local','tok-t5-p2','active',now()),
  -- Team 6: Shadow Vipers
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000011','player11@dev.local','tok-t6-p1','active',now()),
  ('00000000-0000-0000-3000-000000000006','00000000-0000-0000-2000-000000000012','player12@dev.local','tok-t6-p2','active',now()),
  -- Team 7: Arctic Fox
  ('00000000-0000-0000-3000-000000000007','00000000-0000-0000-2000-000000000013','player13@dev.local','tok-t7-p1','active',now()),
  ('00000000-0000-0000-3000-000000000007','00000000-0000-0000-2000-000000000014','player14@dev.local','tok-t7-p2','active',now()),
  -- Team 8: Delta Storm
  ('00000000-0000-0000-3000-000000000008','00000000-0000-0000-2000-000000000015','player15@dev.local','tok-t8-p1','active',now()),
  ('00000000-0000-0000-3000-000000000008','00000000-0000-0000-2000-000000000016','player16@dev.local','tok-t8-p2','active',now()),
  -- Team 9: Night Hunters
  ('00000000-0000-0000-3000-000000000009','00000000-0000-0000-2000-000000000017','player17@dev.local','tok-t9-p1','active',now()),
  ('00000000-0000-0000-3000-000000000009','00000000-0000-0000-2000-000000000018','player18@dev.local','tok-t9-p2','active',now())
on conflict do nothing;

-- ── Availabilities ────────────────────────────────────────────
-- Each window is 17:00–22:00 UTC (5h, enough for a 3h scrim with buffer)
-- Group A users: L1, P1, P2, L2, P3, P4, L3, P5, P6
-- Group B users: L4, P7, P8, L5, P9, P10, L6, P11, P12
-- Group C users: L7, P13, P14, L8, P15, P16, L9, P17, P18

do $$
declare
  -- Group A: Teams 1-3 → Mon 16, Wed 18, Fri 20 Mar 2026
  group_a_users uuid[] := array[
    '00000000-0000-0000-1000-000000000001'::uuid, -- L1
    '00000000-0000-0000-2000-000000000001'::uuid, -- P1
    '00000000-0000-0000-2000-000000000002'::uuid, -- P2
    '00000000-0000-0000-1000-000000000002'::uuid, -- L2
    '00000000-0000-0000-2000-000000000003'::uuid, -- P3
    '00000000-0000-0000-2000-000000000004'::uuid, -- P4
    '00000000-0000-0000-1000-000000000003'::uuid, -- L3
    '00000000-0000-0000-2000-000000000005'::uuid, -- P5
    '00000000-0000-0000-2000-000000000006'::uuid  -- P6
  ];
  group_a_days timestamptz[] := array[
    '2026-03-16 17:00:00+00'::timestamptz, -- Mon
    '2026-03-18 17:00:00+00'::timestamptz, -- Wed
    '2026-03-20 17:00:00+00'::timestamptz  -- Fri
  ];

  -- Group B: Teams 4-6 → Tue 17, Thu 19, Sat 21 Mar 2026
  group_b_users uuid[] := array[
    '00000000-0000-0000-1000-000000000004'::uuid, -- L4
    '00000000-0000-0000-2000-000000000007'::uuid, -- P7
    '00000000-0000-0000-2000-000000000008'::uuid, -- P8
    '00000000-0000-0000-1000-000000000005'::uuid, -- L5
    '00000000-0000-0000-2000-000000000009'::uuid, -- P9
    '00000000-0000-0000-2000-000000000010'::uuid, -- P10
    '00000000-0000-0000-1000-000000000006'::uuid, -- L6
    '00000000-0000-0000-2000-000000000011'::uuid, -- P11
    '00000000-0000-0000-2000-000000000012'::uuid  -- P12
  ];
  group_b_days timestamptz[] := array[
    '2026-03-17 17:00:00+00'::timestamptz, -- Tue
    '2026-03-19 17:00:00+00'::timestamptz, -- Thu
    '2026-03-21 17:00:00+00'::timestamptz  -- Sat
  ];

  -- Group C: Teams 7-9 → Wed 18, Fri 20, Sun 22 Mar 2026
  group_c_users uuid[] := array[
    '00000000-0000-0000-1000-000000000007'::uuid, -- L7
    '00000000-0000-0000-2000-000000000013'::uuid, -- P13
    '00000000-0000-0000-2000-000000000014'::uuid, -- P14
    '00000000-0000-0000-1000-000000000008'::uuid, -- L8
    '00000000-0000-0000-2000-000000000015'::uuid, -- P15
    '00000000-0000-0000-2000-000000000016'::uuid, -- P16
    '00000000-0000-0000-1000-000000000009'::uuid, -- L9
    '00000000-0000-0000-2000-000000000017'::uuid, -- P17
    '00000000-0000-0000-2000-000000000018'::uuid  -- P18
  ];
  group_c_days timestamptz[] := array[
    '2026-03-18 17:00:00+00'::timestamptz, -- Wed
    '2026-03-20 17:00:00+00'::timestamptz, -- Fri
    '2026-03-22 17:00:00+00'::timestamptz  -- Sun
  ];

  uid  uuid;
  day  timestamptz;
begin
  -- Group A
  foreach uid in array group_a_users loop
    foreach day in array group_a_days loop
      insert into public.availabilities (user_id, starts_at, ends_at)
      values (uid, day, day + interval '5 hours')
      on conflict do nothing;
    end loop;
  end loop;

  -- Group B
  foreach uid in array group_b_users loop
    foreach day in array group_b_days loop
      insert into public.availabilities (user_id, starts_at, ends_at)
      values (uid, day, day + interval '5 hours')
      on conflict do nothing;
    end loop;
  end loop;

  -- Group C
  foreach uid in array group_c_users loop
    foreach day in array group_c_days loop
      insert into public.availabilities (user_id, starts_at, ends_at)
      values (uid, day, day + interval '5 hours')
      on conflict do nothing;
    end loop;
  end loop;
end $$;
