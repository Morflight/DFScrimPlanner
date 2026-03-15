-- Profiles (extends auth.users, auto-created via trigger)
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  username text not null,
  timezone text not null default 'UTC',
  role text not null default 'player' check (role in ('leader', 'player', 'filler')),
  created_at timestamptz not null default now()
);

-- Teams
create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  leader_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Team members (invited or active)
create table public.team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  invite_email text not null,
  invite_token text not null unique,
  status text not null default 'invited' check (status in ('invited', 'active')),
  invited_at timestamptz not null default now(),
  activated_at timestamptz
);

-- Availability windows (stored in UTC, must span at least 3h to be matchable)
create table public.availabilities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint valid_window check (ends_at >= starts_at + interval '3 hours')
);

-- Scrims (always 3h, status tracks lifecycle)
create table public.scrims (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles(id) on delete cascade,
  starts_at timestamptz not null,
  status text not null default 'proposed' check (status in ('proposed', 'confirmed', 'cancelled')),
  created_at timestamptz not null default now()
);

-- Scrim <-> Team join
create table public.scrim_teams (
  scrim_id uuid not null references public.scrims(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  primary key (scrim_id, team_id)
);

-- Auto-create profile on user sign-up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, timezone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'timezone', 'UTC'),
    coalesce(new.raw_user_meta_data->>'role', 'player')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
