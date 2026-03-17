# Source Context

SvelteKit conventions: `+page.svelte` for pages, `+page.server.ts` for load functions and form actions, `+server.ts` for API routes. Feature modules in `lib/features/`. Shared components in `lib/components/`.

RLS is enforced on all Supabase tables — never bypass it in client-side code. Use `supabaseAdmin` (service_role) only in server routes when RLS needs to be bypassed for admin operations.

All times stored in UTC. Convert to user's timezone only at render time.
