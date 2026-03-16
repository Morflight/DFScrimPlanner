# API Routes

## SvelteKit Server Routes

| Method | Path | Auth Required | Description |
|--------|------|---------------|-------------|
| GET | `/availability/[userId]` | yes | Load a teammate's profile + future availabilities; redirects to `/availability` if own userId, redirects to `/team` if not a teammate |
| POST | `/availability/[userId]?/save` | yes | Replace a teammate's future availabilities; re-checks teammate relationship on every write; uses `supabaseAdmin` |

## Supabase Direct Calls (client-side)

| Table / RPC | Operation | Auth Required | Notes |
|-------------|-----------|---------------|-------|
|             |           |               |       |

## Error Handling

<!-- Standard error shapes returned by server routes -->
