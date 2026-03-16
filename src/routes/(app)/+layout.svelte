<script lang="ts">
	import { enhance } from '$app/forms';
	import type { LayoutData } from './$types';

	let { data, children }: { data: LayoutData; children: any } = $props();

	let sidebarOpen = $state(false);

	const navLinks = [
		{ href: '/dashboard', label: 'Dashboard' },
		{ href: '/availability', label: 'Availability' },
		{ href: '/team', label: 'My Team' },
		{ href: '/scrims', label: 'Scrims' },
		{ href: '/fillers', label: 'Fillers' },
		{ href: '/profile', label: 'Profile' }
	];

	const isAdmin = $derived(data.profile?.role === 'admin');
</script>

<div class="min-h-screen bg-background md:flex">
	<!-- Mobile top bar -->
	<header
		class="md:hidden fixed top-0 left-0 right-0 z-30 h-12 border-b border-border bg-background flex items-center px-4 gap-3 shrink-0"
	>
		<button
			onclick={() => (sidebarOpen = !sidebarOpen)}
			class="p-1.5 rounded hover:bg-accent transition-colors"
			aria-label="Toggle menu"
		>
			<svg width="18" height="18" viewBox="0 0 18 18" fill="currentColor" aria-hidden="true">
				<rect y="2" width="18" height="2" rx="1" />
				<rect y="8" width="18" height="2" rx="1" />
				<rect y="14" width="18" height="2" rx="1" />
			</svg>
		</button>
		<span class="font-bold text-sm tracking-tight">DFScrimPlanner</span>
	</header>

	<!-- Backdrop -->
	{#if sidebarOpen}
		<div
			class="fixed inset-0 z-40 bg-black/50 md:hidden"
			role="none"
			onclick={() => (sidebarOpen = false)}
		></div>
	{/if}

	<!-- Sidebar -->
	<aside
		class="fixed inset-y-0 left-0 z-50 w-56 border-r border-border bg-background flex flex-col
			transition-transform duration-200 ease-in-out
			{sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
			md:static md:translate-x-0 md:shrink-0"
	>
		<div class="px-4 py-5 border-b border-border">
			<span class="font-bold text-sm tracking-tight">DFScrimPlanner</span>
		</div>

		<nav class="flex-1 px-2 py-4 space-y-0.5">
			{#each navLinks as link}
				<a
					href={link.href}
					onclick={() => (sidebarOpen = false)}
					class="flex items-center px-3 py-2 text-sm rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
				>
					{link.label}
				</a>
			{/each}
			{#if isAdmin}
				<a
					href="/admin/users"
					onclick={() => (sidebarOpen = false)}
					class="flex items-center px-3 py-2 text-sm rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
				>
					Admin
				</a>
			{/if}
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
	<main class="flex-1 min-w-0 overflow-auto pt-12 md:pt-0">
		{@render children()}
	</main>
</div>
