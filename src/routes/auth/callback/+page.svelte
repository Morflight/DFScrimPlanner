<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	onMount(async () => {
		const supabase = data.supabase;

		// Sign out any existing session so the new invite/recovery token takes over.
		await supabase.auth.signOut();

		// Supabase implicit flow puts tokens in the URL fragment (#access_token=...).
		// The server can't see fragments, so we handle them client-side.
		const hash = window.location.hash;
		if (hash) {
			const params = new URLSearchParams(hash.substring(1));
			const accessToken = params.get('access_token');
			const refreshToken = params.get('refresh_token');
			const type = params.get('type');

			if (accessToken && refreshToken) {
				const { error } = await supabase.auth.setSession({
					access_token: accessToken,
					refresh_token: refreshToken
				});
				if (error) {
					await goto('/login', { replaceState: true });
					return;
				}

				// Link team_members row for invite flow (server-side via API)
				if (type === 'invite' || type === 'signup') {
					await fetch('/auth/callback/link', { method: 'POST' });
				}

				// Route based on flow type
				if (type === 'recovery') {
					await goto('/reset-password', { replaceState: true });
				} else if (type === 'invite' || type === 'signup') {
					await goto('/register', { replaceState: true });
				} else {
					await goto('/dashboard', { replaceState: true });
				}
				return;
			}
		}

		// Fallback: check query params (PKCE flow or token_hash flow)
		const url = new URL(window.location.href);
		const code = url.searchParams.get('code');
		const tokenHash = url.searchParams.get('token_hash');
		const type = url.searchParams.get('type');
		const next = url.searchParams.get('next');

		if (code) {
			const { error } = await supabase.auth.exchangeCodeForSession(code);
			if (error) {
				await goto('/login', { replaceState: true });
				return;
			}
		} else if (tokenHash && type) {
			const { error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type: type as any });
			if (error) {
				await goto('/login', { replaceState: true });
				return;
			}
		}

		// Link team_members for invite flow
		if (type === 'invite' || type === 'signup') {
			await fetch('/auth/callback/link', { method: 'POST' });
		}

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
