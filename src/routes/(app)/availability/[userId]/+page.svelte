<script lang="ts">
	import { enhance } from '$app/forms';
	import AvailabilityGrid from '$lib/components/AvailabilityGrid.svelte';
	import WeekNav from '$lib/components/WeekNav.svelte';
	import { slotsFromWindow, alignToWeekStart } from '$lib/utils/timezone';
	import type { ActionData, PageData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const tz = $derived(data.targetProfile.timezone ?? 'UTC');
	const weekStartsOn = $derived<'monday' | 'sunday'>((data as any).profile?.week_starts_on ?? 'monday');

	let saving = $state(false);
	let showConfirm = $state(false);
	let confirmed = $state(false);
	let saveForm = $state<HTMLFormElement | null>(null);
	let weekOffset = $state(0);

	// ── Day helpers ──────────────────────────────────────────────────────────

	function todayInTz(timezone: string): string {
		const parts = new Intl.DateTimeFormat('en-US', {
			timeZone: timezone,
			year: 'numeric',
			month: '2-digit',
			day: '2-digit'
		}).formatToParts(new Date());
		const y = parts.find((p) => p.type === 'year')?.value ?? '';
		const mo = parts.find((p) => p.type === 'month')?.value ?? '';
		const d = parts.find((p) => p.type === 'day')?.value ?? '';
		return `${y}-${mo}-${d}`;
	}

	function addDays(dateStr: string, n: number): string {
		const [y, m, d] = dateStr.split('-').map(Number);
		return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
	}

	function formatDayHeader(dateStr: string): { label: string; sub: string } {
		const date = new Date(dateStr + 'T12:00:00Z');
		return {
			label: new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(date),
			sub: new Intl.DateTimeFormat('en-US', { day: 'numeric', month: 'short' }).format(date)
		};
	}

	// ── Derived grid data ─────────────────────────────────────────────────────

	const days = $derived.by(() => {
		const today = todayInTz(tz);
		const start = addDays(alignToWeekStart(today, weekStartsOn), weekOffset * 7);
		return Array.from({ length: 7 }, (_, i) => {
			const dateStr = addDays(start, i);
			const { label, sub } = formatDayHeader(dateStr);
			return { dateStr, label, sub };
		});
	});

	const weekLabel = $derived.by(() => {
		if (days.length === 0) return '';
		return `${days[0].sub} – ${days[days.length - 1].sub}`;
	});

	const validDates = $derived(new Set(days.map((d) => d.dateStr)));

	const initialSlots = $derived.by(() => {
		const slots = new Set<string>();
		for (const avail of data.availabilities) {
			for (const key of slotsFromWindow(avail.starts_at, avail.ends_at, tz, validDates)) {
				slots.add(key);
			}
		}
		return slots;
	});

	let selectedSlots = $state(new Set<string>());

	$effect(() => {
		selectedSlots = new Set(initialSlots);
	});

	// ── Slot → UTC conversion ─────────────────────────────────────────────────

	function slotKeyToUtc(key: string): Date {
		const approx = new Date(key + ':00Z');
		const inTz = approx.toLocaleString('sv', { timeZone: tz });
		const offsetMs = new Date(inTz.replace(' ', 'T') + 'Z').getTime() - approx.getTime();
		return new Date(approx.getTime() - offsetMs);
	}

	function mergeSlotsToRanges(): { starts_at: string; ends_at: string }[] {
		if (selectedSlots.size === 0) return [];

		const sorted = Array.from(selectedSlots).sort();
		const ranges: { starts_at: string; ends_at: string }[] = [];
		let rangeStart = sorted[0];
		let prev = sorted[0];

		for (let i = 1; i < sorted.length; i++) {
			const cur = sorted[i];
			const diffMin =
				(slotKeyToUtc(cur).getTime() - slotKeyToUtc(prev).getTime()) / 60_000;
			if (diffMin !== 30) {
				const end = slotKeyToUtc(prev);
				end.setMinutes(end.getMinutes() + 30);
				ranges.push({
					starts_at: slotKeyToUtc(rangeStart).toISOString(),
					ends_at: end.toISOString()
				});
				rangeStart = cur;
			}
			prev = cur;
		}

		const end = slotKeyToUtc(prev);
		end.setMinutes(end.getMinutes() + 30);
		ranges.push({ starts_at: slotKeyToUtc(rangeStart).toISOString(), ends_at: end.toISOString() });

		return ranges;
	}

	function confirmSave() {
		showConfirm = false;
		confirmed = true;
		saveForm?.requestSubmit();
	}
</script>

<div class="px-4 py-4 md:p-6 space-y-4">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold tracking-tight">
				{data.targetProfile.username}'s Availability
			</h1>
			<p class="text-sm text-muted-foreground mt-0.5">You are editing a teammate's calendar</p>
		</div>
		<span class="text-sm bg-muted text-muted-foreground px-3 py-1 rounded-full font-medium">
			{tz}
		</span>
	</div>

	{#if (form as any)?.error}
		<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">
			{(form as any).error}
		</p>
	{/if}
	{#if (form as any)?.success}
		<p class="text-sm text-green-700 bg-green-50 px-3 py-2 rounded-md">
			{data.targetProfile.username}'s availability saved.
		</p>
	{/if}

	<!-- Week navigation -->
	<WeekNav {weekLabel} {weekOffset} onnavigate={(delta) => (weekOffset += delta)} />

	<!-- Calendar grid -->
	<AvailabilityGrid {days} {selectedSlots} onchange={(slots) => (selectedSlots = slots)} />

	<!-- Save -->
	<form
		bind:this={saveForm}
		method="POST"
		action="?/save"
		use:enhance={({ formData, cancel }) => {
			formData.set('ranges_json', JSON.stringify(mergeSlotsToRanges()));
			if (!confirmed) {
				cancel();
				showConfirm = true;
				return;
			}
			confirmed = false;
			saving = true;
			return async ({ update }) => {
				saving = false;
				await update();
			};
		}}
	>
		<input type="hidden" name="ranges_json" value="" />
		<button
			type="submit"
			disabled={saving}
			class="px-6 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
		>
			{saving ? 'Saving…' : 'Save availability'}
		</button>
	</form>
</div>

<!-- Confirmation dialog -->
{#if showConfirm}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
		<div class="bg-card border border-border rounded-lg p-6 max-w-sm w-full space-y-4 shadow-lg mx-4">
			<h2 class="text-base font-semibold">Edit teammate's calendar?</h2>
			<p class="text-sm text-muted-foreground">
				Are you sure you want to change your teammate's calendar?
			</p>
			<div class="flex justify-end gap-2">
				<button
					onclick={() => (showConfirm = false)}
					class="px-4 py-2 border border-border rounded-md text-sm font-medium hover:bg-muted transition-colors"
				>
					Cancel
				</button>
				<button
					onclick={confirmSave}
					class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 transition-colors"
				>
					Confirm
				</button>
			</div>
		</div>
	</div>
{/if}
