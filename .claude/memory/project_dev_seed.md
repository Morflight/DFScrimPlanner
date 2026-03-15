---
name: dev-seed-admin
description: seed.sql creates a dev admin account (admin@dev.local / admin1234) after every db-reset; make migrate applies migrations without wiping data
type: project
---

`supabase/seed.sql` creates a dev admin account on every `make db-reset`:
- email: admin@dev.local
- password: admin1234
- username: DevAdmin, role: admin

**Why:** User was recreating their account after every restart; root cause was `make db-reset` wiping all data with no seed to recreate it. Volume persistence (`make stop && make start`) is fine — data survives restarts.

**How to apply:** Use `make migrate` (supabase db push) to apply new migrations without data loss. Only use `make db-reset` when a full clean slate is needed.
