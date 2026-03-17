<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import type { LayoutData } from './$types';

	let { data, children }: { data: LayoutData; children: any } = $props();

	// These pages require an active session even though they live in the (auth) group:
	// - /register: invited user must be authenticated to set their username/password
	// - /reset-password: recovery link establishes a session before the form is shown
	const SESSION_REQUIRED = ['/register', '/reset-password'];

	$effect(() => {
		if (data.session && !SESSION_REQUIRED.includes($page.url.pathname)) {
			goto('/dashboard');
		}
	});
</script>

{@render children()}
