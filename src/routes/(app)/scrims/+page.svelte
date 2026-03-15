<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const tz = $derived(data.profile?.timezone ?? 'UTC');
	let tab = $state<'time-first' | 'teams-first'>('time-first');
	let searching = $state(false);
	let creating = $state(false);

	// Time-first state
	let slotStart = $state('');

	// Teams-first state
	let teamA = $state('');
	let teamB = $state('');

	function fmt(iso: string) {
		return new Intl.DateTimeFormat('en-US', {
			timeZone: tz,
			weekday: 'short',
			month: 'short',
			day: 'numeric',
			hour: 'numeric',
			minute: '2-digit',
			timeZoneName: 'short'
		}).format(new Date(iso));
	}

	// Convert datetime-local (local tz) to UTC ISO
	function localToUtc(localDt: string): string {
		const tzDate = new Date(new Date(localDt + ':00Z').toLocaleString('en-US', { timeZone: tz }));
		const tzUtc = new Date(localDt + ':00Z');
		const offsetMs = tzDate.getTime() - tzUtc.getTime();
		return new Date(new Date(localDt + ':00Z').getTime() - offsetMs).toISOString();
	}

	const timeFirstResults: { id: string; name: string }[] = $derived((form as any)?.timeFirstResults ?? []);
	const teamsFirstResults: { starts_at: string }[] = $derived((form as any)?.teamsFirstResults ?? []);
</script>

<div class="p-8 max-w-4xl space-y-8">
	<div>
		<h1 class="text-2xl font-bold tracking-tight">Scrim Planner</h1>
		<p class="text-sm text-muted-foreground mt-1">Find and schedule 3-hour scrims.</p>
	</div>

	<!-- Tabs -->
	<div class="border-b border-border flex gap-6">
		{#each (['time-first', 'teams-first'] as const) as t}
			<button
				onclick={() => (tab = t)}
				class="pb-2 text-sm font-medium transition-colors border-b-2 -mb-px
					{tab === t ? 'border-primary text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground'}"
			>
				{t === 'time-first' ? 'Time-first' : 'Teams-first'}
			</button>
		{/each}
	</div>

	{#if tab === 'time-first'}
		<!-- TIME-FIRST: pick a slot, see available teams -->
		<section class="space-y-4">
			<p class="text-sm text-muted-foreground">Pick a start time and see which teams are available for a 3-hour scrim.</p>
			{#if form?.timeFirstError}
				<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{form.timeFirstError}</p>
			{/if}
			<form
				method="POST"
				action="?/time-first"
				use:enhance={({ formData }) => {
					const local = formData.get('slot_start_local') as string;
					formData.set('slot_start', localToUtc(local));
					searching = true;
					return async ({ update }) => { searching = false; await update(); };
				}}
				class="flex gap-3 items-end"
			>
				<div class="space-y-1">
					<label class="text-xs font-medium text-muted-foreground" for="slot-time">Slot start ({tz})</label>
					<input
						id="slot-time"
						name="slot_start_local"
						type="datetime-local"
						required
						bind:value={slotStart}
						class="px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
					/>
				</div>
				<button
					type="submit"
					disabled={searching}
					class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
				>
					{searching ? 'Searching…' : 'Find teams'}
				</button>
			</form>

			{#if timeFirstResults.length > 0}
				<div class="space-y-3 pt-2">
					<p class="text-sm font-medium">{timeFirstResults.length} team(s) available for {fmt((form as any).slotStart)}</p>
					{#each timeFirstResults as team}
						<div class="border border-border rounded-lg px-4 py-3 flex items-center justify-between">
							<p class="text-sm font-medium">{team.name}</p>
							<form
								method="POST"
								action="?/create-scrim"
								use:enhance={() => {
									creating = true;
									return async ({ update }) => { creating = false; await update(); };
								}}
							>
								<input type="hidden" name="starts_at" value={(form as any).slotStart} />
								<input type="hidden" name="team_a" value={team.id} />
								<!-- Team B must be selected — for now pick from remaining results -->
								<select name="team_b" required class="mr-2 px-2 py-1 border border-input rounded text-xs bg-background">
									<option value="">vs. team…</option>
									{#each timeFirstResults.filter((t) => t.id !== team.id) as opponent}
										<option value={opponent.id}>{opponent.name}</option>
									{/each}
								</select>
								<button
									type="submit"
									disabled={creating}
									class="text-xs px-3 py-1.5 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 disabled:opacity-50 transition-colors"
								>
									Schedule
								</button>
							</form>
						</div>
					{/each}
				</div>
			{:else if form?.timeFirstResults !== undefined}
				<p class="text-sm text-muted-foreground">No teams are available for that slot.</p>
			{/if}
		</section>
	{:else}
		<!-- TEAMS-FIRST: pick two teams, see common slots -->
		<section class="space-y-4">
			<p class="text-sm text-muted-foreground">Pick two teams and see when they're both free for a 3-hour scrim.</p>
			{#if form?.teamsFirstError}
				<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{form.teamsFirstError}</p>
			{/if}
			<form
				method="POST"
				action="?/teams-first"
				use:enhance={() => {
					searching = true;
					return async ({ update }) => { searching = false; await update(); };
				}}
				class="flex flex-wrap gap-3 items-end"
			>
				{#snippet teamSelect(name: string, id: string, onChange: (v: string) => void)}
					<div class="space-y-1">
						<label class="text-xs font-medium text-muted-foreground" for={name}>Team</label>
						<select
							{id}
							{name}
							required
							onchange={(e) => onChange((e.target as HTMLSelectElement).value)}
							class="px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
						>
							<option value="">Select a team…</option>
							{#each data.teams as team}
								<option value={team.id}>{team.name}</option>
							{/each}
						</select>
					</div>
				{/snippet}

				{@render teamSelect('team_a', 'team-a', (v) => (teamA = v))}
				<span class="text-muted-foreground pb-2">vs.</span>
				{@render teamSelect('team_b', 'team-b', (v) => (teamB = v))}

				<button
					type="submit"
					disabled={searching}
					class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
				>
					{searching ? 'Searching…' : 'Find slots'}
				</button>
			</form>

			{#if teamsFirstResults.length > 0}
				<div class="space-y-2 pt-2">
					<p class="text-sm font-medium">{teamsFirstResults.length} common slot(s) found (next 14 days)</p>
					{#each teamsFirstResults as slot}
						<div class="border border-border rounded-lg px-4 py-3 flex items-center justify-between">
							<p class="text-sm">{fmt(slot.starts_at)}</p>
							<form
								method="POST"
								action="?/create-scrim"
								use:enhance={() => {
									creating = true;
									return async ({ update }) => { creating = false; await update(); };
								}}
							>
								<input type="hidden" name="starts_at" value={slot.starts_at} />
								<input type="hidden" name="team_a" value={teamA} />
								<input type="hidden" name="team_b" value={teamB} />
								<button
									type="submit"
									disabled={creating}
									class="text-xs px-3 py-1.5 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 disabled:opacity-50 transition-colors"
								>
									Schedule
								</button>
							</form>
						</div>
					{/each}
				</div>
			{:else if form?.teamsFirstResults !== undefined}
				<p class="text-sm text-muted-foreground">No common slots in the next 14 days.</p>
			{/if}

			{#if form?.scrimCreated}
				<p class="text-sm text-green-600 bg-green-500/10 px-3 py-2 rounded-md">Scrim proposed! Check your dashboard.</p>
			{/if}
		</section>
	{/if}
</div>
