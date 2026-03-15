<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData } from './$types';
	import TeamScrimCalendar from '$lib/components/TeamScrimCalendar.svelte';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const tz = $derived(data.profile?.timezone ?? 'UTC');
	let tab = $state<'time-first' | 'teams-first'>('time-first');
	let searching = $state(false);
	let creating = $state(false);

	// Calendar slot selection (slot key = "YYYY-MM-DDTHH:MM" in viewer tz)
	let selectedSlot = $state<string | null>(null);

	// Teams picked from results (max 2)
	let pickedTeams = $state<string[]>([]);

	// Pick-teams state
	let ptTeams = $state<string[]>([]);
	let ptSlot = $state<string | null>(null);

	// Persist time-first results across the create-scrim action
	let savedResults = $state<{
		teams: { id: string; name: string }[];
		fillers: { id: string; username: string; timezone: string }[];
		slotStart: string;
	} | null>(null);

	$effect(() => {
		if ((form as any)?.timeFirstResults !== undefined) {
			savedResults = {
				teams: (form as any).timeFirstResults ?? [],
				fillers: (form as any).fillerResults ?? [],
				slotStart: (form as any).slotStart ?? ''
			};
			pickedTeams = [];
		}
	});

	// Convert slot key ("YYYY-MM-DDTHH:MM" in viewer tz) to UTC ISO
	function slotKeyToUtc(slotKey: string): string {
		const localDt = slotKey; // "YYYY-MM-DDTHH:MM"
		const tzDate = new Date(
			new Date(localDt + ':00Z').toLocaleString('en-US', { timeZone: tz })
		);
		const tzUtc = new Date(localDt + ':00Z');
		const offsetMs = tzDate.getTime() - tzUtc.getTime();
		return new Date(new Date(localDt + ':00Z').getTime() - offsetMs).toISOString();
	}

	// Format a UTC ISO string in viewer tz
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

	// Format selected slot key as "Mon Mar 16, 17:00 – 20:00"
	function fmtSlotKey(slotKey: string): string {
		const sepIdx = slotKey.indexOf('T');
		const datePart = slotKey.slice(0, sepIdx);
		const timePart = slotKey.slice(sepIdx + 1);
		const [h, m] = timePart.split(':').map(Number);
		const endTotalMin = h * 60 + m + 180;
		const endH = Math.floor(endTotalMin / 60) % 24;
		const endM = endTotalMin % 60;
		const startStr = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
		const endStr = `${String(endH).padStart(2, '0')}:${String(endM).padStart(2, '0')}`;
		// Parse date as UTC to get weekday/month labels (date string is already in viewer tz)
		const d = new Date(datePart + 'T00:00:00Z');
		const dayLabel = new Intl.DateTimeFormat('en-US', {
			timeZone: 'UTC',
			weekday: 'short',
			month: 'short',
			day: 'numeric'
		}).format(d);
		return `${dayLabel}, ${startStr} – ${endStr}`;
	}

	function toggleTeam(id: string) {
		if (pickedTeams.includes(id)) {
			pickedTeams = pickedTeams.filter((t) => t !== id);
		} else if (pickedTeams.length < 5) {
			pickedTeams = [...pickedTeams, id];
		}
	}

	// Viewer's own team members with slotSets (for time-first calendar)
	const myTeamMemberSlots = $derived(
		(data.myTeamMembers ?? []).map((m) => ({ ...m, slotSet: new Set(m.slots) }))
	);

	// Teams visible in the pick-teams grid (those selected as chips)
	const ptGridTeams = $derived(
		(data.teamSlotData ?? [])
			.filter((t) => ptTeams.includes(t.id))
			.map((t) => ({ ...t, slotSet: new Set(t.slots) }))
	);

	function togglePtTeam(id: string) {
		if (ptTeams.includes(id)) {
			ptTeams = ptTeams.filter((t) => t !== id);
			ptSlot = null;
		} else if (ptTeams.length < 5) {
			ptTeams = [...ptTeams, id];
		}
	}
</script>

<div class="p-8 max-w-6xl space-y-6">
	<div>
		<h1 class="text-2xl font-bold tracking-tight">Scrim Planner</h1>
		<p class="text-sm text-muted-foreground mt-1">Schedule 3-hour scrims between teams.</p>
	</div>

	<!-- Tabs -->
	<div class="border-b border-border flex gap-6">
		{#each (['time-first', 'teams-first'] as const) as t}
			<button
				onclick={() => (tab = t)}
				class="pb-2 text-sm font-medium transition-colors border-b-2 -mb-px
					{tab === t
					? 'border-primary text-foreground'
					: 'border-transparent text-muted-foreground hover:text-foreground'}"
			>
				{t === 'time-first' ? 'Pick a time' : 'Pick teams'}
			</button>
		{/each}
	</div>

	{#if tab === 'time-first'}
		<!-- ── PICK A TIME ─────────────────────────────────────────── -->
		<section class="space-y-4">
			<p class="text-sm text-muted-foreground">
				Click a slot to select a 3-hour scrim window, then confirm to see available teams.
			</p>

			{#if myTeamMemberSlots.length > 0}
				<TeamScrimCalendar
					days={data.gridDays}
					teams={myTeamMemberSlots}
					{selectedSlot}
					restrictToAvailable={true}
					entryLabel="member"
					onselect={(s) => {
						selectedSlot = s;
						savedResults = null;
						pickedTeams = [];
					}}
				/>
			{:else}
				<p class="text-sm text-amber-500 bg-amber-500/10 px-3 py-2 rounded-md">
					You need to be part of a team to use this view. Your team's availability will appear here.
				</p>
			{/if}

			<!-- Selected slot summary + confirm -->
			<div class="flex items-center gap-4 pt-1">
				{#if selectedSlot}
					<span class="text-sm font-medium">{fmtSlotKey(selectedSlot)}</span>
				{:else}
					<span class="text-sm text-muted-foreground">No slot selected</span>
				{/if}

				{#if form?.timeFirstError}
					<span class="text-sm text-destructive">{form.timeFirstError}</span>
				{/if}

				<form
					method="POST"
					action="?/time-first"
					use:enhance={({ formData }) => {
						formData.set('slot_start', slotKeyToUtc(selectedSlot!));
						searching = true;
						return async ({ update }) => {
							searching = false;
							await update();
						};
					}}
				>
					<input type="hidden" name="slot_start" value="" />
					<button
						type="submit"
						disabled={!selectedSlot || searching}
						class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
					>
						{searching ? 'Searching…' : 'Find teams'}
					</button>
				</form>
			</div>

			<!-- Results -->
			{#if savedResults}
				<div class="space-y-5 pt-2 border-t border-border">
					<p class="text-sm text-muted-foreground pt-4">
						Results for <span class="font-medium text-foreground"
							>{fmtSlotKey(savedResults.slotStart.slice(0, 16))}</span
						>
					</p>

					<!-- Teams -->
					{#if savedResults.teams.length === 0}
						<div class="space-y-1">
							<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">
								Available teams
							</h3>
							<p class="text-sm text-muted-foreground">No teams are available for this slot.</p>
						</div>
					{:else}
						<div class="space-y-3">
							<div class="flex items-baseline gap-3">
								<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">
									Available teams
								</h3>
								<span class="text-xs text-muted-foreground"
									>{savedResults.teams.length} team{savedResults.teams.length !== 1
										? 's'
										: ''} — pick 5 to schedule</span
								>
							</div>
							<div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
								{#each savedResults.teams as team}
									{@const picked = pickedTeams.includes(team.id)}
									{@const disabled = !picked && pickedTeams.length >= 5}
									<button
										onclick={() => toggleTeam(team.id)}
										disabled={disabled}
										class="px-4 py-3 rounded-lg border text-left text-sm font-medium transition-colors
											{picked
											? 'border-primary bg-primary/10 text-foreground'
											: 'border-border bg-card text-foreground hover:border-primary/50 hover:bg-muted/40'}
											disabled:opacity-40 disabled:cursor-not-allowed"
									>
										{team.name}
										{#if picked}
											<span class="ml-1 text-xs text-primary">✓</span>
										{/if}
									</button>
								{/each}
							</div>

							{#if pickedTeams.length > 0}
								<div class="flex flex-wrap items-center gap-2">
									{#each pickedTeams as id}
										<span class="text-xs px-2 py-1 rounded bg-primary/10 text-primary font-medium">
											{savedResults.teams.find((t) => t.id === id)?.name}
										</span>
									{/each}
									<span class="text-xs text-muted-foreground ml-1">{pickedTeams.length}/5</span>
								</div>
							{/if}

							{#if pickedTeams.length === 5}
								<form
									method="POST"
									action="?/create-scrim"
									use:enhance={() => {
										creating = true;
										return async ({ update }) => {
											creating = false;
											await update();
										};
									}}
								>
									<input type="hidden" name="starts_at" value={savedResults.slotStart} />
									{#each pickedTeams as id}
										<input type="hidden" name="team_id" value={id} />
									{/each}
									<button
										type="submit"
										disabled={creating}
										class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
									>
										{creating ? 'Scheduling…' : 'Create scrim'}
									</button>
								</form>
							{/if}
						</div>
					{/if}

					<!-- Fillers -->
					{#if savedResults.fillers.length > 0}
						<div class="space-y-3">
							<div class="flex items-baseline gap-3">
								<h3
									class="text-sm font-semibold uppercase tracking-wider {savedResults.teams.length < 2
										? 'text-amber-500'
										: 'text-muted-foreground'}"
								>
									Available fillers
								</h3>
								{#if savedResults.teams.length < 2}
									<span class="text-xs text-amber-500/80">not enough teams — fillers can fill the gap</span>
								{/if}
							</div>
							<div class="flex flex-wrap gap-2">
								{#each savedResults.fillers as filler}
									<div
										class="px-3 py-2 rounded-lg border border-border bg-card text-sm flex items-center gap-2"
									>
										<span class="font-medium">{filler.username}</span>
										<span class="text-xs text-muted-foreground">{filler.timezone}</span>
									</div>
								{/each}
							</div>
						</div>
					{/if}

					{#if (form as any)?.scrimCreated}
						<p class="text-sm text-green-600 bg-green-500/10 px-3 py-2 rounded-md">
							Scrim proposed! Check your dashboard.
						</p>
					{/if}

					{#if (form as any)?.error}
						<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">
							{(form as any).error}
						</p>
					{/if}
				</div>
			{/if}
		</section>
	{:else}
		<!-- ── PICK TEAMS ─────────────────────────────────────────── -->
		<section class="space-y-5">
			<p class="text-sm text-muted-foreground">
				Select up to 5 opponent teams, then click a scrim-ready slot on the calendar to schedule.
			</p>

			<!-- Team chips -->
			<div class="space-y-2">
				<div class="flex items-baseline gap-3">
					<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Teams</h3>
					<span class="text-xs text-muted-foreground">{ptTeams.length}/5 selected</span>
				</div>
				<div class="flex flex-wrap gap-2">
					{#each data.teamSlotData as team}
						{@const picked = ptTeams.includes(team.id)}
						{@const disabled = !picked && ptTeams.length >= 5}
						<button
							onclick={() => togglePtTeam(team.id)}
							disabled={disabled}
							class="px-3 py-1.5 rounded-full border text-sm font-medium transition-colors
								{picked
								? 'border-primary bg-primary/10 text-foreground'
								: 'border-border bg-card text-muted-foreground hover:border-primary/50 hover:text-foreground'}
								disabled:opacity-40 disabled:cursor-not-allowed"
						>
							{team.name}
							{#if picked}<span class="ml-1 text-xs text-primary">✓</span>{/if}
						</button>
					{/each}
				</div>
			</div>

			<!-- Calendar (only when teams selected) -->
			{#if ptTeams.length > 0}
				<TeamScrimCalendar
					days={data.gridDays}
					teams={ptGridTeams}
					selectedSlot={ptSlot}
					onselect={(s) => (ptSlot = s)}
				/>

				<!-- Slot summary + create form -->
				<div class="flex items-center gap-4 pt-1">
					{#if ptSlot}
						<span class="text-sm font-medium">{fmtSlotKey(ptSlot)}</span>
					{:else}
						<span class="text-sm text-muted-foreground">No slot selected</span>
					{/if}

					{#if ptTeams.length === 5 && ptSlot}
						<form
							method="POST"
							action="?/create-scrim"
							use:enhance={() => {
								creating = true;
								return async ({ update }) => {
									creating = false;
									await update();
								};
							}}
						>
							<input type="hidden" name="starts_at" value={slotKeyToUtc(ptSlot)} />
							{#each ptTeams as id}
								<input type="hidden" name="team_id" value={id} />
							{/each}
							<button
								type="submit"
								disabled={creating}
								class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
							>
								{creating ? 'Scheduling…' : 'Create scrim'}
							</button>
						</form>
					{:else if ptTeams.length < 5}
						<span class="text-xs text-muted-foreground">Select {5 - ptTeams.length} more team{5 - ptTeams.length !== 1 ? 's' : ''}</span>
					{/if}
				</div>
			{/if}

			{#if (form as any)?.scrimCreated}
				<p class="text-sm text-green-600 bg-green-500/10 px-3 py-2 rounded-md">
					Scrim proposed! Check your dashboard.
				</p>
			{/if}

			{#if (form as any)?.error}
				<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">
					{(form as any).error}
				</p>
			{/if}
		</section>
	{/if}
</div>
