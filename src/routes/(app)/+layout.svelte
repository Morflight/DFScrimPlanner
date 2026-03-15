<script lang="ts">
	import { enhance } from '$app/forms';
	import type { LayoutData } from './$types';

	let { data, children }: { data: LayoutData; children: any } = $props();

	const navLinks = [
		{ href: '/dashboard', label: 'Dashboard' },
		{ href: '/availability', label: 'Availability' },
		{ href: '/team', label: 'My Team' },
		{ href: '/scrims', label: 'Scrims' },
		{ href: '/fillers', label: 'Fillers' }
	];
</script>

<div class="min-h-screen bg-background flex">
	<!-- Sidebar -->
	<aside class="w-56 border-r border-border flex flex-col shrink-0">
		<div class="px-4 py-5 border-b border-border">
			<span class="font-bold text-sm tracking-tight">DFScrimPlanner</span>
		</div>

		<nav class="flex-1 px-2 py-4 space-y-0.5">
			{#each navLinks as link}
				<a
					href={link.href}
					class="flex items-center px-3 py-2 text-sm rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
				>
					{link.label}
				</a>
			{/each}
		</nav>

		<div class="px-4 py-4 border-t border-border space-y-1">
			<p class="text-xs font-medium truncate">{data.profile?.username ?? data.user?.email}</p>
			<p class="text-xs text-muted-foreground capitalize">{data.profile?.role ?? 'player'}</p>
			<form method="POST" action="/signout" use:enhance class="pt-1">
				<button
					type="submit"
					class="text-xs text-muted-foreground hover:text-foreground transition-colors"
				>
					Sign out
				</button>
			</form>
		</div>
	</aside>

	<!-- Main content -->
	<main class="flex-1 overflow-auto">
		{@render children()}
	</main>
</div>
