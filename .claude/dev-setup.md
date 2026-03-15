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
npm install                  # Install SvelteKit + all dependencies
supabase init                # Initialize Supabase CLI (creates supabase/ folder)
# Copy .env.local.example to .env.local
supabase start               # Start local Supabase stack; copy output keys into .env.local
make dev                     # Start app container on reverse-proxy
```

App: https://dfscrimplanner.local.com
Supabase Studio: http://localhost:54323
Supabase API: http://localhost:54321

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
