<script lang="ts">
	import { enhance } from '$app/forms';
	import AvailabilityGrid from '$lib/components/AvailabilityGrid.svelte';
	import { slotsFromWindow } from '$lib/utils/timezone';
	import type { ActionData, PageData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const tz = $derived(data.profile?.timezone ?? 'UTC');
	let saving = $state(false);

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
		// Use noon UTC to avoid date-boundary issues
		const date = new Date(dateStr + 'T12:00:00Z');
		return {
			label: new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(date),
			sub: new Intl.DateTimeFormat('en-US', { day: 'numeric', month: 'short' }).format(date)
		};
	}

	// ── Derived grid data ─────────────────────────────────────────────────────

	const days = $derived.by(() => {
		const today = todayInTz(tz);
		return Array.from({ length: 7 }, (_, i) => {
			const dateStr = addDays(today, i);
			const { label, sub } = formatDayHeader(dateStr);
			return { dateStr, label, sub };
		});
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

	/** Convert a "YYYY-MM-DDTHH:MM" local-tz slot key to a UTC Date. */
	function slotKeyToUtc(key: string): Date {
		// Treat key as UTC temporarily to get an approximate Date
		const approx = new Date(key + ':00Z');
		// Format that UTC moment in the user's tz using the 'sv' locale, which produces
		// "YYYY-MM-DD HH:MM:SS" — safe to re-parse as UTC by appending Z.
		// This avoids depending on the browser's local timezone.
		const inTz = approx.toLocaleString('sv', { timeZone: tz }); // e.g. "2026-03-15 15:30:00"
		const offsetMs = new Date(inTz.replace(' ', 'T') + 'Z').getTime() - approx.getTime();
		return new Date(approx.getTime() - offsetMs);
	}

	/** Merge sorted consecutive 30-min slot keys into UTC availability ranges. */
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
				// Close the current range
				const end = slotKeyToUtc(prev);
				end.setMinutes(end.getMinutes() + 30);
				ranges.push({ starts_at: slotKeyToUtc(rangeStart).toISOString(), ends_at: end.toISOString() });
				rangeStart = cur;
			}
			prev = cur;
		}

		// Close the last range
		const end = slotKeyToUtc(prev);
		end.setMinutes(end.getMinutes() + 30);
		ranges.push({ starts_at: slotKeyToUtc(rangeStart).toISOString(), ends_at: end.toISOString() });

		return ranges;
	}
</script>

<div class="p-6 max-w-5xl space-y-4">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<h1 class="text-2xl font-bold tracking-tight">My Availability</h1>
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
		<p class="text-sm text-green-700 bg-green-50 px-3 py-2 rounded-md">Availability saved.</p>
	{/if}

	<!-- Calendar grid -->
	<AvailabilityGrid {days} {selectedSlots} onchange={(slots) => (selectedSlots = slots)} />

	<!-- Save -->
	<form
		method="POST"
		action="?/save"
		use:enhance={({ formData }) => {
			formData.set('ranges_json', JSON.stringify(mergeSlotsToRanges()));
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
