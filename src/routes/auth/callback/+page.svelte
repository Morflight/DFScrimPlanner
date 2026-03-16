<script lang="ts">
	import { onMount } from 'svelte';

	onMount(() => {
		// Read tokens from URL fragment IMMEDIATELY — before any async work.
		const hash = window.location.hash;
		const hp = hash ? new URLSearchParams(hash.substring(1)) : new URLSearchParams();
		const accessToken = hp.get('access_token');
		const refreshToken = hp.get('refresh_token');
		const type = hp.get('type');
		const next = new URL(window.location.href).searchParams.get('next');

		if (!accessToken || !refreshToken) {
			window.location.href = '/login';
			return;
		}

		// POST tokens to server endpoint — only the server can set httpOnly cookies.
		const form = document.createElement('form');
		form.method = 'POST';
		form.action = '/auth/callback';

		for (const [k, v] of Object.entries({
			access_token: accessToken,
			refresh_token: refreshToken,
			type: type ?? '',
			next: next ?? ''
		})) {
			const input = document.createElement('input');
			input.type = 'hidden';
			input.name = k;
			input.value = v;
			form.appendChild(input);
		}

		document.body.appendChild(form);
		form.submit();
	});
</script>

<div class="min-h-screen flex items-center justify-center">
	<p class="text-sm text-muted-foreground">Signing you in…</p>
</div>
