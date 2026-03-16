<script lang="ts">
	import { onMount } from 'svelte';
	import { goto, invalidateAll } from '$app/navigation';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	onMount(async () => {
		const supabase = data.supabase;

		// ── 1. Capture tokens immediately before any async work ──────────
		let accessToken: string | null = null;
		let refreshToken: string | null = null;
		let type: string | null = null;
		let next: string | null = null;

		const hash = window.location.hash;
		if (hash) {
			const hp = new URLSearchParams(hash.substring(1));
			accessToken = hp.get('access_token');
			refreshToken = hp.get('refresh_token');
			type = hp.get('type');
		}

		// Also check query params (PKCE / token_hash flow)
		const qp = new URL(window.location.href).searchParams;
		const code = qp.get('code');
		const tokenHash = qp.get('token_hash');
		type = type ?? qp.get('type');
		next = qp.get('next');

		// ── 2. Sign out existing session ─────────────────────────────────
		await supabase.auth.signOut();

		// ── 3. Establish the new session from the invite/recovery token ──
		let error: any = null;

		if (accessToken && refreshToken) {
			({ error } = await supabase.auth.setSession({
				access_token: accessToken,
				refresh_token: refreshToken
			}));
		} else if (code) {
			({ error } = await supabase.auth.exchangeCodeForSession(code));
		} else if (tokenHash && type) {
			({ error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type: type as any }));
		}

		if (error) {
			await goto('/login', { replaceState: true });
			return;
		}

		// Refresh server-side session so subsequent SSR requests see the new user
		await invalidateAll();

		// ── 4. Link user_id on team_members (does NOT activate — registration does that) ──
		if (type === 'invite' || type === 'signup') {
			await fetch('/auth/callback/link', { method: 'POST' });
		}

		// ── 5. Route ─────────────────────────────────────────────────────
		if (next) {
			await goto(next, { replaceState: true });
		} else if (type === 'recovery') {
			await goto('/reset-password', { replaceState: true });
		} else if (type === 'invite' || type === 'signup') {
			await goto('/register', { replaceState: true });
		} else {
			await goto('/dashboard', { replaceState: true });
		}
	});
</script>

<div class="min-h-screen flex items-center justify-center">
	<p class="text-sm text-muted-foreground">Signing you in…</p>
</div>
