<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const tz = $derived(data.profile?.timezone ?? 'UTC');
	let adding = $state(false);
	let removing = $state<string | null>(null);

	// Default: today at current hour (rounded), 4h window
	const now = new Date();
	const roundedHour = new Date(now);
	roundedHour.setMinutes(0, 0, 0);
	roundedHour.setHours(roundedHour.getHours() + 1);

	function toLocalInputValue(date: Date): string {
		// Format as YYYY-MM-DDTHH:mm in local time for datetime-local input
		const pad = (n: number) => String(n).padStart(2, '0');
		const tzDate = new Date(date.toLocaleString('en-US', { timeZone: tz }));
		return `${tzDate.getFullYear()}-${pad(tzDate.getMonth() + 1)}-${pad(tzDate.getDate())}T${pad(tzDate.getHours())}:${pad(tzDate.getMinutes())}`;
	}

	let defaultStart = $state(toLocalInputValue(roundedHour));
	let defaultEnd = $state(() => {
		const end = new Date(roundedHour);
		end.setHours(end.getHours() + 4);
		return toLocalInputValue(end);
	});

	function formatWindow(startsAt: string, endsAt: string): string {
		const fmt = (iso: string) =>
			new Intl.DateTimeFormat('en-US', {
				timeZone: tz,
				weekday: 'short',
				month: 'short',
				day: 'numeric',
				hour: 'numeric',
				minute: '2-digit'
			}).format(new Date(iso));
		const hours = (new Date(endsAt).getTime() - new Date(startsAt).getTime()) / 3_600_000;
		return `${fmt(startsAt)} → ${fmt(endsAt)} (${hours}h)`;
	}

	// Convert local datetime-local input (interpreted in user tz) to UTC ISO
	function localInputToUtc(localDt: string): string {
		// datetime-local gives "YYYY-MM-DDTHH:mm" — we treat this as the user's local time
		// We need to send it to the server as a UTC ISO string
		// Use Intl to find the offset
		const dt = new Date(localDt); // parsed as UTC (wrong), we'll correct below
		const formatter = new Intl.DateTimeFormat('en-US', {
			timeZone: tz,
			year: 'numeric',
			month: '2-digit',
			day: '2-digit',
			hour: '2-digit',
			minute: '2-digit',
			second: '2-digit',
			hour12: false
		});
		// Get current UTC offset for this tz at the given moment
		// This is an approximation; close enough for hourly slots
		const tzDate = new Date(new Date(localDt + ':00Z').toLocaleString('en-US', { timeZone: tz }));
		const tzUtc = new Date(localDt + ':00Z');
		const offsetMs = tzDate.getTime() - tzUtc.getTime();
		return new Date(new Date(localDt + ':00Z').getTime() - offsetMs).toISOString();
	}
</script>

<div class="p-8 max-w-3xl space-y-8">
	<div>
		<h1 class="text-2xl font-bold tracking-tight">My Availability</h1>
		<p class="text-sm text-muted-foreground mt-1">
			Times shown in your timezone: <strong>{tz}</strong>
		</p>
	</div>

	{#if (form as any)?.error}
		<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{(form as any).error}</p>
	{/if}

	<!-- Add availability window -->
	<section class="space-y-3">
		<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Add Window</h2>
		<form
			method="POST"
			action="?/add"
			use:enhance={({ formData }) => {
				// Convert local datetime-local values to UTC before submission
				const start = formData.get('starts_at_local') as string;
				const end = formData.get('ends_at_local') as string;
				formData.set('starts_at', localInputToUtc(start));
				formData.set('ends_at', localInputToUtc(end));
				adding = true;
				return async ({ update }) => { adding = false; await update(); };
			}}
			class="space-y-3"
		>
			<div class="grid grid-cols-2 gap-3">
				<div class="space-y-1">
					<label class="text-xs font-medium text-muted-foreground" for="starts">From</label>
					<input
						id="starts"
						name="starts_at_local"
						type="datetime-local"
						required
						value={defaultStart}
						class="w-full px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
					/>
				</div>
				<div class="space-y-1">
					<label class="text-xs font-medium text-muted-foreground" for="ends">To</label>
					<input
						id="ends"
						name="ends_at_local"
						type="datetime-local"
						required
						value={defaultEnd}
						class="w-full px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
					/>
				</div>
			</div>
			<p class="text-xs text-muted-foreground">Minimum 3 hours (one scrim duration).</p>
			<button
				type="submit"
				disabled={adding}
				class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
			>
				{adding ? 'Saving…' : 'Add availability'}
			</button>
		</form>
	</section>

	<!-- Existing windows -->
	<section class="space-y-3">
		<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Your Windows</h2>
		{#if data.availabilities.length === 0}
			<p class="text-sm text-muted-foreground">No availability set yet.</p>
		{:else}
			<div class="space-y-2">
				{#each data.availabilities as slot}
					<div class="border border-border rounded-lg px-4 py-3 flex items-center justify-between">
						<p class="text-sm">{formatWindow(slot.starts_at, slot.ends_at)}</p>
						<form
							method="POST"
							action="?/remove"
							use:enhance={() => {
								removing = slot.id;
								return async ({ update }) => { removing = null; await update(); };
							}}
						>
							<input type="hidden" name="id" value={slot.id} />
							<button
								type="submit"
								disabled={removing === slot.id}
								class="text-xs text-destructive hover:text-destructive/80 disabled:opacity-50 transition-colors"
							>
								Remove
							</button>
						</form>
					</div>
				{/each}
			</div>
		{/if}
	</section>
</div>
