<script lang="ts">
	import { onMount } from 'svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	onMount(async () => {
		// ── 1. Read tokens from URL fragment IMMEDIATELY ─────────────────
		const hash = window.location.hash;
		const hp = hash ? new URLSearchParams(hash.substring(1)) : new URLSearchParams();
		const accessToken = hp.get('access_token');
		const refreshToken = hp.get('refresh_token');
		const type = hp.get('type');

		// Query params (e.g. ?next=/reset-password from forgot-password flow)
		const next = new URL(window.location.href).searchParams.get('next');

		// ── 2. Set new session (overwrites any existing session in cookies) ──
		if (accessToken && refreshToken) {
			const { error } = await data.supabase.auth.setSession({
				access_token: accessToken,
				refresh_token: refreshToken
			});
			if (error) {
				window.location.href = '/login';
				return;
			}
		} else {
			// No tokens — nothing to exchange
			window.location.href = '/login';
			return;
		}

		// ── 3. Hard redirect — full page reload picks up new cookies ─────
		if (next) {
			window.location.href = next;
		} else if (type === 'invite' || type === 'signup') {
			window.location.href = '/register';
		} else if (type === 'recovery') {
			window.location.href = '/reset-password';
		} else {
			window.location.href = '/dashboard';
		}
	});
</script>

<div class="min-h-screen flex items-center justify-center">
	<p class="text-sm text-muted-foreground">Signing you in…</p>
</div>
