# API Routes

## SvelteKit Server Routes

| Method | Path | Auth Required | Description |
|--------|------|---------------|-------------|
| GET | `/auth/callback` | — | Exchange Supabase token for session; links team_members row; routes: `type=invite` → `/register`, `type=recovery` → `/reset-password`, `next` param overrides |
| POST | `/forgot-password` | no | Send password reset email via `supabase.auth.resetPasswordForEmail` |
| POST | `/reset-password` | yes (recovery session) | Set new password via `supabase.auth.updateUser`; validates match |
| POST | `/register` | yes (invite session) | Complete profile (username, timezone, password) for newly invited users |
| POST | `/team?/invite-member` | yes (leader or member) | Create team_members row + send Supabase Auth invite email |
| POST | `/admin/users?/create-user` | yes (admin only) | Invite a user with a specific role via `supabaseAdmin.auth.admin.inviteUserByEmail` |
| GET | `/availability/[userId]` | yes | Load a teammate's profile + future availabilities; redirects to `/availability` if own userId, redirects to `/team` if not a teammate |
| POST | `/availability/[userId]?/save` | yes | Replace a teammate's future availabilities; re-checks teammate relationship on every write; uses `supabaseAdmin` |

## Supabase Direct Calls (client-side)

| Table / RPC | Operation | Auth Required | Notes |
|-------------|-----------|---------------|-------|
|             |           |               |       |

## Error Handling

<!-- Standard error shapes returned by server routes -->
