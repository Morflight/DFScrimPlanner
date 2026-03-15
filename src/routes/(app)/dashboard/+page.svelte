<script lang="ts">
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	function formatDate(iso: string, tz: string) {
		return new Intl.DateTimeFormat('en-US', {
			weekday: 'short',
			month: 'short',
			day: 'numeric',
			hour: 'numeric',
			minute: '2-digit',
			timeZone: tz,
			timeZoneName: 'short'
		}).format(new Date(iso));
	}

	const tz = $derived(data.profile?.timezone ?? 'UTC');
</script>

<div class="p-8 max-w-4xl space-y-8">
	<div>
		<h1 class="text-2xl font-bold tracking-tight">Dashboard</h1>
		<p class="text-sm text-muted-foreground mt-1">Welcome back, {data.profile?.username ?? 'Player'}</p>
	</div>

	<!-- Team card -->
	<section>
		<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Your Team</h2>
		{#if data.team}
			<div class="border border-border rounded-lg p-4 flex items-center justify-between">
				<div>
					<p class="font-medium">{data.team.name}</p>
					<p class="text-xs text-muted-foreground">{data.isLeader ? 'You are the team leader' : 'Member'}</p>
				</div>
				<a
					href="/team"
					class="text-xs px-3 py-1.5 border border-border rounded-md hover:bg-accent transition-colors"
				>
					Manage
				</a>
			</div>
		{:else}
			<div class="border border-dashed border-border rounded-lg p-6 text-center text-sm text-muted-foreground">
				You're not on a team yet.
				<a href="/team" class="ml-1 underline underline-offset-2 hover:text-foreground">Create or join one</a>
			</div>
		{/if}
	</section>

	<!-- Upcoming scrims -->
	<section>
		<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Upcoming Scrims</h2>
		{#if data.upcomingScrims.length > 0}
			<div class="space-y-2">
				{#each data.upcomingScrims as scrim}
					<div class="border border-border rounded-lg px-4 py-3 flex items-center justify-between">
						<div>
							<p class="text-sm font-medium">{formatDate(scrim.starts_at, tz)}</p>
							<p class="text-xs text-muted-foreground">Duration: 3 hours</p>
						</div>
						<span class="text-xs px-2 py-0.5 rounded-full capitalize
							{scrim.status === 'confirmed' ? 'bg-green-500/10 text-green-600 dark:text-green-400' :
							 scrim.status === 'proposed' ? 'bg-yellow-500/10 text-yellow-600 dark:text-yellow-400' : ''}">
							{scrim.status}
						</span>
					</div>
				{/each}
			</div>
		{:else}
			<div class="border border-dashed border-border rounded-lg p-6 text-center text-sm text-muted-foreground">
				No upcoming scrims.
				<a href="/scrims" class="ml-1 underline underline-offset-2 hover:text-foreground">Schedule one</a>
			</div>
		{/if}
	</section>

	<!-- Pending invites (leader only) -->
	{#if data.isLeader && data.pendingInvites.length > 0}
		<section>
			<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Pending Invites</h2>
			<div class="space-y-2">
				{#each data.pendingInvites as invite}
					<div class="border border-border rounded-lg px-4 py-3 flex items-center justify-between">
						<p class="text-sm">{invite.invite_email}</p>
						<span class="text-xs text-muted-foreground">Awaiting acceptance</span>
					</div>
				{/each}
			</div>
		</section>
	{/if}

	<!-- Quick links -->
	<section>
		<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Quick Actions</h2>
		<div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
			{#each [
				{ href: '/availability', label: 'Set Availability' },
				{ href: '/scrims', label: 'Plan a Scrim' },
				{ href: '/fillers', label: 'Find Fillers' },
				{ href: '/team', label: 'Team Roster' }
			] as action}
				<a
					href={action.href}
					class="border border-border rounded-lg p-3 text-sm font-medium text-center hover:bg-accent transition-colors"
				>
					{action.label}
				</a>
			{/each}
		</div>
	</section>
</div>
