# Auth Flows

## Invite Flow (team member or admin-created user)

1. Leader/member clicks **Invite** on `/team`, or admin clicks **Send invite** on `/admin/users`
2. Server calls `supabaseAdmin.auth.admin.inviteUserByEmail(email, { redirectTo: '/auth/callback' })`
3. Supabase sends email with a one-time link
4. User clicks link → Supabase verifies token → redirects to `/auth/callback?code=...` (PKCE flow)
5. Server-side callback exchanges code for session via `exchangeCodeForSession(code)` — overwrites any existing session cookies
6. Callback links `team_members` row (sets `user_id` only — status stays `invited`)
7. Callback redirects to `/register`
8. User sets username, timezone, password → register action activates `team_members` row (`status=active`) → redirected to `/dashboard`

## Sign In

1. `/login` form → POST action → `supabase.auth.signInWithPassword({ email, password })`
2. On success → `redirect(303, '/dashboard')`
3. On failure → `fail(400, { error: message })`

## Forgot Password

1. `/forgot-password` form → POST action → `supabase.auth.resetPasswordForEmail(email, { redirectTo: '/auth/callback?next=/reset-password' })`
2. Supabase sends reset email
3. User clicks link → Supabase verifies → `GET /auth/callback?code=...&next=/reset-password` (PKCE)
4. Callback exchanges code for session, redirects to `/reset-password` (via `next` param)
5. `/reset-password` form → POST action → `supabase.auth.updateUser({ password })`
6. On success → `redirect(303, '/dashboard')`

## Sign Out

- `/signout` POST action → `supabase.auth.signOut()` → redirect to `/login`

## Session Handling

- `hooks.server.ts` creates a server-side Supabase client with SSR cookie handling on every request
- `safeGetSession()` validates and refreshes the session; exposed via `locals`
- `(app)/+layout.server.ts` calls `safeGetSession()` and redirects to `/login` if no session

## Protected Routes

| Route | Guard | Redirect if unauthorized |
|-------|-------|--------------------------|
| `(app)/*` | `(app)/+layout.server.ts` — requires session | `/login` |
| `/admin/*` | `admin/+layout.server.ts` — requires `role = 'admin'` | `/dashboard` |
| `/register` | page load — requires session (user followed invite link) | `/login` |
| `/reset-password` | page load — requires session (user followed reset link) | `/login` |
