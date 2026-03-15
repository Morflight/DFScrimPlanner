# Codebase

## Frontend

### Routing

```
src/routes/
  (auth)/
    login/              # Email/password sign-in
    register/           # Invite-token-based registration + account activation
  (app)/
    dashboard/          # Overview: upcoming scrims, team status
    availability/       # Set/edit own availability windows
    team/               # Team management (leader: invite, remove; member: view)
    scrims/
      time-first/       # Pick a time slot → see available teams
      teams-first/      # Pick two teams → see common availability
    fillers/            # Browse filler players; search by date/time
```

### Features

| Feature folder | Components | Stores / State | Notes |
|----------------|------------|----------------|-------|
| `auth/` | LoginForm, RegisterForm | session store | Invite token consumed on activation |
| `availability/` | AvailabilityGrid, SlotPicker | availability store | All times in UTC; display in user tz |
| `teams/` | TeamRoster, InviteForm, MemberCard | team store | Leader-only mutations |
| `scrims/` | TimeFirstPlanner, TeamsFirstPlanner, ScrimCard | scrim store | Slot matching logic in utils/ |
| `fillers/` | FillerCard, FillerSearch | — | Read-only; search by date + time range |

### Shared Components

| Component | Location | Purpose |
|-----------|----------|---------|
| AvailabilityGrid | `lib/components/AvailabilityGrid.svelte` | 7-day × 48-slot clickable grid; click+drag to select; emits `onchange(Set<string>)` with slot keys (`"YYYY-MM-DDTHH:MM"` in user tz); accepts `readonly={true}` to disable interaction |
| TeamAvailabilityGrid | `lib/components/TeamAvailabilityGrid.svelte` | Read-only multi-member grid: one colored bar row per member per day + a Team row showing overlap count; green highlight when ≥3 members overlap in a ≥3h contiguous run; legend below. Props: `days: Day[]`, `members: { userId, username, slotSet: Set<string> }[]` |
| ScrimCalendar | `lib/components/ScrimCalendar.svelte` | Interactive scrim slot picker: 7-day × 48-slot grid; click a slot to select a 3h window (highlighted in primary color); slots 21:30–23:30 non-selectable (would cross midnight); click selected slot to deselect. Props: `days: Day[]`, `selectedSlot: string \| null`, `onselect: (slot: string \| null) => void` |
| TeamScrimCalendar | `lib/components/TeamScrimCalendar.svelte` | Combined team-availability + scrim-slot picker: per-team colored bars (one per selected team) + green highlight when all teams free; clickable 3h selection like ScrimCalendar. Props: `days: Day[]`, `teams: { id, name, slotSet: Set<string> }[]`, `selectedSlot: string \| null`, `onselect: (slot: string \| null) => void` |
| TimezoneSelect | `lib/components/` | IANA timezone picker (planned) |
| UserAvatar | `lib/components/` | Profile avatar + name (planned) |

## Backend

### Server Routes

| Method | Path | Auth Required | Description |
|--------|------|---------------|-------------|
|        |      |               | To be filled as routes are implemented |

### Supabase Integration

| File | Purpose |
|------|---------|
| `src/lib/server/supabase.ts` | Admin client (service_role) — invite creation, trigger management |
| `src/hooks.server.ts`        | Session validation + refresh on every request |

### Business Logic

- **Slot matching**: availability windows are stored as UTC ranges; matching finds overlaps ≥ 3h between two teams' aggregate windows. Lives in `src/lib/utils/slot-matching.ts`.
- **Invite flow**: leader triggers invite → server creates `team_members` row with `invite_token` + sends email via Supabase Auth invite → user follows link → `register/` route activates account and links `user_id` on the `team_members` row.
- **Timezone display**: all `timestamptz` values from DB are converted to the user's stored timezone at render time using `Intl.DateTimeFormat` or a date-fns-tz helper.

## Data Flow

- **Availability input**: user selects slots in UI → form action → `availabilities` INSERT via Supabase client (RLS: own rows only)
- **Scrim planning (time-first)**: organizer selects date/time → server route queries `availabilities` for all teams, finds 3h overlaps, returns matching teams
- **Scrim planning (teams-first)**: organizer selects teams → server route fetches both teams' availabilities, intersects windows, returns available slots
- **Invite**: leader submits email → `+server.ts` → Supabase admin client creates `team_members` row + sends invite email → user clicks link → `register/` page activates account
