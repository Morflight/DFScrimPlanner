# Common Tasks

## Dev Stack

```bash
make dev                       # Start Supabase local stack + SvelteKit dev server
make stop                      # Stop dev stack (app + Supabase)
make build                     # Production build
make deploy                    # Push to master → Netlify auto-deploys
```

## Testing

```bash
make test                      # Run all Vitest tests
npx vitest run tests/<file>    # Run a single test file
npx vitest watch               # Watch mode (dev)
```

## Database / Supabase

```bash
make types                     # Regenerate src/lib/types/database.ts from local schema
make migration name=<name>     # Create a new migration file in supabase/migrations/
make db-reset                  # Drop and rebuild local DB (migrations + seed)
supabase start                 # Start Supabase local stack manually
supabase stop                  # Stop Supabase local stack
supabase status                # Show local Supabase service URLs + keys
supabase db diff               # Show schema drift vs last migration
```

## Git

```bash
git checkout master && git pull                    # Update master
git checkout -b feat/<name>                        # New feature branch
git checkout -b fix/<name>                         # Bug fix branch
git add <files> && git commit -m "message"         # Stage and commit
```
