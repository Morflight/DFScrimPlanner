<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto } from '$app/navigation';
	import type { ActionData, PageData } from './$types';
	import TeamAvailabilityGrid from '$lib/components/TeamAvailabilityGrid.svelte';
	import WeekNav from '$lib/components/WeekNav.svelte';

	let { data, form }: { data: PageData; form: ActionData } = $props();
	let creatingTeam = $state(false);
	let inviting = $state(false);
	let removing = $state<string | null>(null);
	let leaving = $state(false);

	const gridMembers = $derived(
		(data.memberSlots ?? []).map((m) => ({ ...m, slotSet: new Set(m.slots) }))
	);

	function navigateWeek(delta: number) {
		const next = (data.weekOffset ?? 0) + delta;
		const params = new URLSearchParams();
		if (next !== 0) params.set('week', String(next));
		goto(`?${params.toString()}`, { invalidateAll: true });
	}

	const weekLabel = $derived.by(() => {
		const days = data.gridDays;
		if (!days || days.length === 0) return '';
		return `${days[0].sub} – ${days[days.length - 1].sub}`;
	});
</script>

<div class="px-4 py-6 md:p-8 space-y-8">
	<div>
		<h1 class="text-2xl font-bold tracking-tight">My Team</h1>
	</div>

	{#if form?.error}
		<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{form.error}</p>
	{/if}

	{#if !data.team}
		<!-- Create team -->
		<section class="space-y-4">
			<p class="text-sm text-muted-foreground">You're not part of a team. Create one to start scheduling scrims.</p>
			<form
				method="POST"
				action="?/create-team"
				use:enhance={() => {
					creatingTeam = true;
					return async ({ update }) => { creatingTeam = false; await update(); };
				}}
				class="flex gap-2 max-w-sm"
			>
				<input
					name="name"
					type="text"
					required
					minlength="2"
					placeholder="Team name"
					class="flex-1 px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
				/>
				<button
					type="submit"
					disabled={creatingTeam}
					class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
				>
					{creatingTeam ? 'Creating…' : 'Create'}
				</button>
			</form>
		</section>
	{:else}
		<!-- Team header -->
		<section class="border border-border rounded-lg p-4 flex items-center justify-between">
			<div>
				<h2 class="font-semibold">{data.team.name}</h2>
				<p class="text-xs text-muted-foreground mt-0.5">{data.isLeader ? 'You are the team leader' : 'Member'}</p>
			</div>
			{#if !data.isLeader}
				<form
					method="POST"
					action="?/leave-team"
					use:enhance={() => {
						leaving = true;
						return async ({ update }) => { leaving = false; await update(); };
					}}
				>
					<button
						type="submit"
						disabled={leaving}
						onclick={(e) => { if (!confirm('Leave this team?')) e.preventDefault(); }}
						class="text-xs text-destructive hover:text-destructive/80 transition-colors disabled:opacity-50"
					>
						{leaving ? 'Leaving…' : 'Leave team'}
					</button>
				</form>
			{/if}
		</section>

		<!-- Roster -->
		<section class="space-y-3">
			<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Roster</h3>
			{#if data.members.length === 0}
				<p class="text-sm text-muted-foreground">No active members yet.</p>
			{:else}
				<div class="space-y-2">
					{#each data.members as member}
						<div class="border border-border rounded-lg px-4 py-3 flex items-center justify-between">
							<div>
								<div class="flex items-center gap-2">
									<p class="text-sm font-medium">{(member.profiles as any)?.username}</p>
									{#if (member as any).isLeader}
										<span class="text-xs text-amber-600 dark:text-amber-400 font-medium">Leader</span>
									{/if}
								</div>
								<p class="text-xs text-muted-foreground">{(member.profiles as any)?.timezone ?? ''}</p>
							</div>
							<div class="flex items-center gap-3">
								{#if member.user_id && member.user_id !== data.profile?.id}
									<a
										href="/availability/{member.user_id}"
										class="text-xs text-muted-foreground hover:text-foreground transition-colors"
									>
										Edit availability
									</a>
								{/if}
								{#if data.isLeader && !(member as any).isLeader}
									<form
										method="POST"
										action="?/remove-member"
										use:enhance={() => {
											removing = member.id;
											return async ({ update }) => { removing = null; await update(); };
										}}
									>
										<input type="hidden" name="member_id" value={member.id} />
										<button
											type="submit"
											disabled={removing === member.id}
											class="text-xs text-destructive hover:text-destructive/80 transition-colors disabled:opacity-50"
										>
											Remove
										</button>
									</form>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</section>

		<!-- Pending invites -->
		{#if data.pendingInvites.length > 0}
			<section class="space-y-3">
				<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Pending Invites</h3>
				<div class="space-y-2">
					{#each data.pendingInvites as invite}
						<div class="border border-dashed border-border rounded-lg px-4 py-3 flex items-center justify-between">
							<p class="text-sm">{invite.invite_email}</p>
							<div class="flex items-center gap-3">
								<span class="text-xs text-muted-foreground">Invite sent</span>
								{#if data.isLeader}
									<form
										method="POST"
										action="?/cancel-invite"
										use:enhance={() => {
											return async ({ update }) => { await update(); };
										}}
									>
										<input type="hidden" name="member_id" value={invite.id} />
										<button
											type="submit"
											class="text-xs text-destructive hover:text-destructive/80 transition-colors"
										>
											Cancel
										</button>
									</form>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			</section>
		{/if}

		<!-- Team Availability -->
		<section class="space-y-3">
			<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Team Availability</h3>
			{#if data.members.length < 2}
				<p class="text-sm text-muted-foreground">Add at least two active members to see team availability.</p>
			{:else}
				<WeekNav {weekLabel} weekOffset={data.weekOffset ?? 0} onnavigate={navigateWeek} />
				<TeamAvailabilityGrid days={data.gridDays} members={gridMembers} />
			{/if}
		</section>

		<!-- Invite member (leader or active member) -->
		{#if data.team}
			<section class="space-y-3">
				<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Invite a Teammate</h3>
				{#if form?.inviteError}
					<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{form.inviteError}</p>
				{/if}
				{#if form?.inviteSuccess}
					<p class="text-sm text-green-600 bg-green-500/10 px-3 py-2 rounded-md">Invite sent successfully.</p>
				{/if}
				<form
					method="POST"
					action="?/invite-member"
					use:enhance={() => {
						inviting = true;
						return async ({ update }) => { inviting = false; await update(); };
					}}
					class="flex gap-2 max-w-sm"
				>
					<input
						name="email"
						type="email"
						required
						placeholder="teammate@example.com"
						class="flex-1 px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
					/>
					<button
						type="submit"
						disabled={inviting}
						class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
					>
						{inviting ? 'Sending…' : 'Invite'}
					</button>
				</form>
			</section>
		{/if}
	{/if}
</div>
