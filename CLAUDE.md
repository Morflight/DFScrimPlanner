## Project Configuration

- **Language**: TypeScript
- **Package Manager**: npm
- **Add-ons**: none

---

# DFScrimPlanner

Scrim scheduling app for Delta Force teams — matches team availabilities to 3-hour scrim slots, with timezone support and filler player management.

@.claude/features.md
@.claude/schema.md
@.claude/api-routes.md
@.claude/auth-flows.md
@.claude/codebase.md

## Common Commands

```bash
make start        # Start Supabase local stack + SvelteKit dev server
make stop         # Stop dev stack
make test         # Run Vitest
make build        # Production build (used by Netlify)
make deploy       # Push to master → Netlify auto-deploys
make types        # Regenerate Supabase TypeScript types
make migration name=<name>   # Create a new migration
make db-reset     # Reset DB: re-apply all migrations + seed
```

Supabase Studio (dev): http://localhost:54323
App (dev): https://dfscrimplanner.local.com

## Architecture

### Routing (SvelteKit)

```
src/routes/
  (auth)/               # Unauthenticated: login, register (invite), accept-invite
  (app)/                # Authenticated
    dashboard/          # Overview: upcoming scrims, team status
    availability/       # Set/edit own availability
    team/               # Team management (leader only)
    scrims/             # Scrim planner: time-first and teams-first views
    fillers/            # Browse/request filler players
```

### Lib Structure (feature-first)

```
src/lib/
  features/
    auth/               # Invite-based registration, session helpers
    availability/       # Availability grid logic, timezone conversion
    teams/              # Team CRUD, member management
    scrims/             # Scrim creation, slot matching, organizer views
    fillers/            # Solo player pool, filler search
  components/           # Shared UI (shadcn-svelte primitives + wrappers)
  server/               # Supabase admin client, server-only utilities
  types/
    database.ts         # Generated Supabase types (run make types)
  utils/                # Timezone helpers, date formatting, slot matching
  app.html
  app.d.ts              # Extend Locals with Supabase session
```

### Infrastructure

- **Dev**: `docker-compose.dev.yml` — `dfscrimplanner_app` on `reverse-proxy` network, routed to `https://dfscrimplanner.local.com` via Traefik. Supabase local stack via `supabase start` CLI.
- **Production**: Netlify auto-deploys from `master`. Supabase hosted project handles DB + auth.
- **ReverseProxy must be running** for the dev hostname to resolve.

### Key Design Points

- All times stored in UTC; converted to user's timezone in the UI
- Scrims are always 3 hours — availability slots must cover a 3h window to be considered a match
- Invitation flow: leader creates team → invites teammates by email → invite link activates account
- RLS enforces data isolation: users only see their own data + public scrim listings
