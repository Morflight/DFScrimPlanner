<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const tz = $derived(data.profile?.timezone ?? 'UTC');
	const isFiller = $derived(data.profile?.role === 'filler');
	let toggling = $state(false);
	let filterDate = $state('');

	function fmt(iso: string, userTz = tz) {
		return new Intl.DateTimeFormat('en-US', {
			timeZone: userTz,
			month: 'short',
			day: 'numeric',
			hour: 'numeric',
			minute: '2-digit'
		}).format(new Date(iso));
	}

	function windowStr(a: { starts_at: string; ends_at: string }, playerTz: string) {
		const hours = (new Date(a.ends_at).getTime() - new Date(a.starts_at).getTime()) / 3_600_000;
		return `${fmt(a.starts_at, playerTz)} – ${fmt(a.ends_at, playerTz)} (${hours}h)`;
	}

	const fillers = $derived(
		filterDate
			? data.fillers.filter((f: any) =>
					(f.availabilities ?? []).some((a: any) => {
						const d = new Date(filterDate);
						const start = new Date(a.starts_at);
						const end = new Date(a.ends_at);
						return start <= new Date(d.getTime() + 24 * 3_600_000) && end >= d;
					})
				)
			: data.fillers
	);
</script>

<div class="px-4 py-6 md:p-8 max-w-3xl space-y-8">
	<div>
		<h1 class="text-2xl font-bold tracking-tight">Filler Players</h1>
		<p class="text-sm text-muted-foreground mt-1">Solo players available to fill in for teams.</p>
	</div>

	<!-- Register/unregister as filler -->
	<section class="border border-border rounded-lg p-4 flex items-center justify-between">
		<div>
			<p class="text-sm font-medium">
				{isFiller ? 'You are registered as a filler' : 'Make yourself available as a filler'}
			</p>
			<p class="text-xs text-muted-foreground mt-0.5">
				{isFiller
					? 'Teams can see you in this list. Your availability windows are public.'
					: 'Register to appear in this list. Your availability will be visible to team leaders.'}
			</p>
		</div>
		<form
			method="POST"
			action={isFiller ? '?/unregister-filler' : '?/register-filler'}
			use:enhance={() => {
				toggling = true;
				return async ({ update }) => { toggling = false; await update(); };
			}}
		>
			<button
				type="submit"
				disabled={toggling}
				class="px-3 py-1.5 text-xs font-medium rounded-md border border-border hover:bg-accent disabled:opacity-50 transition-colors"
			>
				{toggling ? '…' : isFiller ? 'Unregister' : 'Register as filler'}
			</button>
		</form>
	</section>

	{#if form?.error}
		<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{form.error}</p>
	{/if}

	<!-- Filter by date -->
	<section class="space-y-3">
		<div class="flex items-center gap-3">
			<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Available Fillers</h2>
			<div class="flex items-center gap-2 ml-auto">
				<label class="text-xs text-muted-foreground" for="filter-date">Filter by date</label>
				<input
					id="filter-date"
					type="date"
					bind:value={filterDate}
					class="px-2 py-1 border border-input rounded text-xs bg-background focus:outline-none focus:ring-2 focus:ring-ring"
				/>
				{#if filterDate}
					<button
						onclick={() => (filterDate = '')}
						class="text-xs text-muted-foreground hover:text-foreground"
					>
						Clear
					</button>
				{/if}
			</div>
		</div>

		{#if fillers.length === 0}
			<p class="text-sm text-muted-foreground">
				{filterDate ? 'No fillers available on that date.' : 'No filler players registered yet.'}
			</p>
		{:else}
			<div class="space-y-3">
				{#each fillers as filler}
					<div class="border border-border rounded-lg p-4 space-y-2">
						<div class="flex items-center justify-between">
							<div>
								<p class="text-sm font-medium">{filler.username}</p>
								<p class="text-xs text-muted-foreground">{filler.timezone}</p>
							</div>
						</div>
						{#if filler.availabilities?.length > 0}
							<div class="space-y-1">
								{#each filler.availabilities as slot}
									<p class="text-xs text-muted-foreground">{windowStr(slot, filler.timezone)}</p>
								{/each}
							</div>
						{:else}
							<p class="text-xs text-muted-foreground">No upcoming availability.</p>
						{/if}
					</div>
				{/each}
			</div>
		{/if}
	</section>
</div>
