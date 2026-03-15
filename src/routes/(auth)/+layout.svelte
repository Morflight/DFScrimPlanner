<script lang="ts">
	import { goto } from '$app/navigation';
	import type { LayoutData } from './$types';

	let { data, children }: { data: LayoutData; children: any } = $props();

	$effect(() => {
		if (data.session) goto('/dashboard');
	});
</script>

{@render children()}
