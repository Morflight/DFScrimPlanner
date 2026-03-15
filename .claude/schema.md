# Database Schema

## Tables

### `profiles`
Extends Supabase auth.users. Created automatically on user sign-up via trigger.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | no | — | FK → auth.users.id |
| `username` | `text` | no | — | Display name |
| `timezone` | `text` | no | `'UTC'` | IANA timezone string |
| `role` | `text` | no | `'player'` | `'leader'`, `'player'`, `'filler'` |
| `created_at` | `timestamptz` | no | `now()` | — |

### `teams`

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `name` | `text` | no | — | — |
| `leader_id` | `uuid` | no | — | FK → profiles.id |
| `created_at` | `timestamptz` | no | `now()` | — |

### `team_members`

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `team_id` | `uuid` | no | — | FK → teams.id |
| `user_id` | `uuid` | yes | — | FK → profiles.id — null until invite accepted |
| `invite_email` | `text` | no | — | Email the invite was sent to |
| `invite_token` | `text` | no | — | Unique token for invite link |
| `status` | `text` | no | `'invited'` | `'invited'`, `'active'` |
| `invited_at` | `timestamptz` | no | `now()` | — |
| `activated_at` | `timestamptz` | yes | — | Set when account is activated |

### `availabilities`
Each row is a continuous available window. Scrims are 3h — a window must span ≥ 3h to be matchable.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `user_id` | `uuid` | no | — | FK → profiles.id |
| `starts_at` | `timestamptz` | no | — | UTC |
| `ends_at` | `timestamptz` | no | — | UTC |
| `created_at` | `timestamptz` | no | `now()` | — |

### `scrims`

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `organizer_id` | `uuid` | no | — | FK → profiles.id |
| `starts_at` | `timestamptz` | no | — | UTC; duration always 3h |
| `status` | `text` | no | `'proposed'` | `'proposed'`, `'confirmed'`, `'cancelled'` |
| `created_at` | `timestamptz` | no | `now()` | — |

### `scrim_teams`

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `scrim_id` | `uuid` | no | — | FK → scrims.id |
| `team_id` | `uuid` | no | — | FK → teams.id |

## Row-Level Security Policies

| Table | Policy Name | Command | Using / Check |
|-------|-------------|---------|---------------|
| `profiles` | own profile | SELECT, UPDATE | `auth.uid() = id` |
| `teams` | own team (leader) | ALL | `auth.uid() = leader_id` |
| `teams` | member read | SELECT | user is in team_members |
| `team_members` | own membership | SELECT, UPDATE | `auth.uid() = user_id` |
| `team_members` | leader manage | ALL | user is leader of the team |
| `availabilities` | own availability | ALL | `auth.uid() = user_id` |
| `availabilities` | filler public read | SELECT | profile.role = 'filler' |
| `scrims` | organizer manage | ALL | `auth.uid() = organizer_id` |
| `scrims` | participant read | SELECT | user is in a scrim_team |
| `scrim_teams` | organizer manage | ALL | user is scrim organizer |

## Relationships

- `profiles.id` → `auth.users.id` (1:1, created by trigger)
- `teams.leader_id` → `profiles.id`
- `team_members.team_id` → `teams.id`
- `team_members.user_id` → `profiles.id` (nullable until invite accepted)
- `availabilities.user_id` → `profiles.id`
- `scrims.organizer_id` → `profiles.id`
- `scrim_teams.scrim_id` → `scrims.id`
- `scrim_teams.team_id` → `teams.id`

## Migrations

| File | Description |
|------|-------------|
|      |             |
