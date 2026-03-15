# Dev Setup

## Prerequisites

- Node.js LTS
- Supabase CLI — `npm install -g supabase` or `npm install supabase --save-dev`
- Docker + Docker Compose + Make
- **ReverseProxy must be running** — provides the `reverse-proxy` network and TLS
- mkcert cert for `dfscrimplanner.local.com` (handled by ReverseProxy)
- DNS entry in `/etc/hosts`: `127.0.0.1 dfscrimplanner.local.com`

## First-Time Setup

```bash
make init        # Scaffold SvelteKit + run supabase init (both via containers — no local installs needed)
make start       # Start Supabase local stack + SvelteKit app container
```

On first `make start`, copy the keys from `supabase start` output into `.env.local`:
```
PUBLIC_SUPABASE_URL=http://host.docker.internal:54321
PUBLIC_SUPABASE_ANON_KEY=<anon key from supabase start output>
SUPABASE_SERVICE_ROLE_KEY=<service_role key from supabase start output>
```

App: https://dfscrimplanner.local.com
Supabase Studio: http://localhost:54323
Supabase API: http://localhost:54321 (host) / http://host.docker.internal:54321 (from app container)

## Environment Variables

| Variable | File | Description |
|----------|------|-------------|
| `PUBLIC_SUPABASE_URL` | `.env` | Supabase project URL (local or hosted) |
| `PUBLIC_SUPABASE_ANON_KEY` | `.env` | Supabase anon key — public, safe in browser |
| `SUPABASE_SERVICE_ROLE_KEY` | `.env.local` | Secret — server-side only, never expose client-side |

- `.env` — checked in, public keys only (placeholder values)
- `.env.local` — gitignored, filled from `supabase start` output for dev; Netlify UI for prod
- Production `SUPABASE_SERVICE_ROLE_KEY` → set in Netlify UI + GitHub Actions secrets

## Gotchas

> Populate as setup issues are discovered.
