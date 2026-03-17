# App Context

SvelteKit + Supabase project. Entry point: `src/routes/`. Auth via `@supabase/ssr` in `hooks.server.ts`. All npm commands run inside the `dfscrimplanner_app` container. Must use `adapter-netlify` in `svelte.config.js`.

Supabase config and migrations live in `supabase/`. Types are generated into `src/lib/types/database.ts` — run `make types` from the project root after any migration.
