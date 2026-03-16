<script lang="ts">
	import { Sun, Moon, User, Globe, Shield } from 'lucide-svelte';
	import { theme } from '$lib/stores/theme';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	const profile = (data as any).profile;
	const user = (data as any).user;

	const isDark = $derived($theme === 'dark');

	const roleColors: Record<string, string> = {
		admin: 'bg-red-500/15 text-red-600 dark:text-red-400',
		leader: 'bg-amber-500/15 text-amber-600 dark:text-amber-400',
		player: 'bg-blue-500/15 text-blue-600 dark:text-blue-400',
		filler: 'bg-green-500/15 text-green-600 dark:text-green-400'
	};

	const role: string = profile?.role ?? 'player';
	const roleClass = roleColors[role] ?? roleColors.player;
	const initial = (profile?.username ?? user?.email ?? '?')[0].toUpperCase();
</script>

<div class="px-4 py-6 md:p-8 max-w-2xl">
	<div class="mb-8">
		<h1 class="text-2xl font-bold tracking-tight">Profile</h1>
		<p class="text-sm text-muted-foreground mt-1">Manage your account settings and preferences.</p>
	</div>

	<!-- Account card -->
	<section class="rounded-xl border border-border bg-card mb-6">
		<div class="px-6 py-4 border-b border-border">
			<h2 class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Account</h2>
		</div>
		<div class="px-6 py-5 flex items-center gap-5">
			<!-- Avatar -->
			<div
				class="w-14 h-14 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-xl font-bold shrink-0 select-none"
			>
				{initial}
			</div>
			<!-- Info -->
			<div class="flex-1 min-w-0">
				<p class="font-semibold truncate">{profile?.username ?? '—'}</p>
				<p class="text-sm text-muted-foreground truncate mt-0.5">{user?.email ?? '—'}</p>
			</div>
			<!-- Role badge -->
			<span class="text-xs font-medium px-2.5 py-1 rounded-full capitalize shrink-0 {roleClass}">
				{role}
			</span>
		</div>
		<div class="px-6 py-4 border-t border-border grid grid-cols-2 gap-4">
			<div class="flex items-center gap-3">
				<Globe size={15} class="text-muted-foreground shrink-0" />
				<div>
					<p class="text-xs text-muted-foreground">Timezone</p>
					<p class="text-sm font-medium">{profile?.timezone ?? 'UTC'}</p>
				</div>
			</div>
			<div class="flex items-center gap-3">
				<Shield size={15} class="text-muted-foreground shrink-0" />
				<div>
					<p class="text-xs text-muted-foreground">Role</p>
					<p class="text-sm font-medium capitalize">{role}</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Appearance card -->
	<section class="rounded-xl border border-border bg-card">
		<div class="px-6 py-4 border-b border-border">
			<h2 class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
				Appearance
			</h2>
		</div>
		<div class="px-6 py-6">
			<div class="flex items-center justify-between gap-6">
				<div>
					<p class="text-sm font-medium">Theme</p>
					<p class="text-xs text-muted-foreground mt-0.5">
						{isDark ? 'Dark mode is on — easy on the eyes.' : 'Light mode is on — bright and clear.'}
					</p>
				</div>

				<!-- The slider -->
				<button
					type="button"
					onclick={() => theme.toggle()}
					aria-label="Toggle theme"
					class="relative flex items-center w-48 h-12 rounded-full p-1 overflow-hidden cursor-pointer shrink-0 transition-all duration-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
					style="background: {isDark
						? 'linear-gradient(135deg, oklch(0.2 0.08 264), oklch(0.28 0.12 280))'
						: 'linear-gradient(135deg, oklch(0.96 0.08 85), oklch(0.9 0.12 75))'}"
				>
					<!-- Background sparkles (dark) / rays (light) -->
					{#if isDark}
						<span
							class="absolute inset-0 pointer-events-none"
							aria-hidden="true"
							style="
								background-image:
									radial-gradient(circle, oklch(0.9 0 0 / 0.8) 1px, transparent 1px),
									radial-gradient(circle, oklch(0.9 0 0 / 0.5) 1px, transparent 1px);
								background-size: 30px 30px, 17px 17px;
								background-position: 0 0, 8px 8px;
								transition: opacity 0.5s;
							"
						></span>
					{:else}
						<span
							class="absolute inset-0 pointer-events-none"
							aria-hidden="true"
							style="
								background: radial-gradient(ellipse at 30% 50%, oklch(1 0.15 85 / 0.6) 0%, transparent 60%);
								transition: opacity 0.5s;
							"
						></span>
					{/if}

					<!-- Sliding thumb -->
					<span
						class="absolute top-1 bottom-1 rounded-full shadow-md transition-all duration-300 ease-[cubic-bezier(0.4,0,0.2,1)] z-10"
						style="
							width: calc(50% - 4px);
							{isDark ? 'left: 50%' : 'left: 4px'};
							background: {isDark
							? 'oklch(0.15 0.04 264)'
							: 'oklch(1 0 0)'};
							box-shadow: {isDark
							? '0 2px 8px oklch(0.1 0.1 264 / 0.6), inset 0 1px 0 oklch(1 0 0 / 0.1)'
							: '0 2px 8px oklch(0.5 0.05 85 / 0.3), inset 0 1px 0 oklch(1 0 0 / 0.8)'};
						"
					></span>

					<!-- Sun label -->
					<span
						class="relative z-20 flex flex-1 items-center justify-center gap-1.5 text-xs font-semibold transition-all duration-300 select-none"
						style="color: {isDark ? 'oklch(0.7 0.05 264)' : 'oklch(0.4 0.1 75)'}"
					>
						<Sun size={13} />
						Light
					</span>

					<!-- Moon label -->
					<span
						class="relative z-20 flex flex-1 items-center justify-center gap-1.5 text-xs font-semibold transition-all duration-300 select-none"
						style="color: {isDark ? 'oklch(0.85 0.08 264)' : 'oklch(0.65 0.03 264)'}"
					>
						<Moon size={13} />
						Dark
					</span>
				</button>
			</div>

			<!-- Preview swatch -->
			<div class="mt-6 grid grid-cols-2 gap-3">
				<button
					type="button"
					onclick={() => { if (isDark) theme.toggle(); }}
					class="group relative rounded-lg border-2 p-3 text-left transition-all duration-200 cursor-pointer {!isDark
						? 'border-primary shadow-sm'
						: 'border-border hover:border-muted-foreground/50'}"
				>
					{#if !isDark}
						<span
							class="absolute top-2 right-2 w-2 h-2 rounded-full bg-primary"
						></span>
					{/if}
					<div
						class="w-full h-14 rounded-md mb-2 overflow-hidden"
						style="background: oklch(1 0 0); border: 1px solid oklch(0.9 0 0)"
					>
						<div style="height: 8px; background: oklch(0.97 0 0); border-bottom: 1px solid oklch(0.9 0 0)"></div>
						<div class="flex gap-1 p-1.5">
							<div style="width: 28px; height: 28px; background: oklch(0.97 0 0); border-radius: 4px"></div>
							<div class="flex-1 flex flex-col gap-1">
								<div style="height: 6px; background: oklch(0.9 0 0); border-radius: 2px; width: 70%"></div>
								<div style="height: 5px; background: oklch(0.93 0 0); border-radius: 2px; width: 50%"></div>
							</div>
						</div>
					</div>
					<p class="text-xs font-medium flex items-center gap-1.5">
						<Sun size={11} />
						Light
					</p>
				</button>

				<button
					type="button"
					onclick={() => { if (!isDark) theme.toggle(); }}
					class="group relative rounded-lg border-2 p-3 text-left transition-all duration-200 cursor-pointer {isDark
						? 'border-primary shadow-sm'
						: 'border-border hover:border-muted-foreground/50'}"
				>
					{#if isDark}
						<span
							class="absolute top-2 right-2 w-2 h-2 rounded-full bg-primary"
						></span>
					{/if}
					<div
						class="w-full h-14 rounded-md mb-2 overflow-hidden"
						style="background: oklch(0.145 0 0); border: 1px solid oklch(0.25 0 0)"
					>
						<div style="height: 8px; background: oklch(0.2 0 0); border-bottom: 1px solid oklch(0.25 0 0)"></div>
						<div class="flex gap-1 p-1.5">
							<div style="width: 28px; height: 28px; background: oklch(0.22 0 0); border-radius: 4px"></div>
							<div class="flex-1 flex flex-col gap-1">
								<div style="height: 6px; background: oklch(0.28 0 0); border-radius: 2px; width: 70%"></div>
								<div style="height: 5px; background: oklch(0.25 0 0); border-radius: 2px; width: 50%"></div>
							</div>
						</div>
					</div>
					<p class="text-xs font-medium flex items-center gap-1.5">
						<Moon size={11} />
						Dark
					</p>
				</button>
			</div>
		</div>
	</section>
</div>
