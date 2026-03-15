<script lang="ts">
	const SLOTS: string[] = Array.from({ length: 48 }, (_, i) => {
		const h = Math.floor(i / 2);
		const m = i % 2 === 0 ? '00' : '30';
		return `${String(h).padStart(2, '0')}:${m}`;
	});

	// Last valid scrim start: 21:00 (index 42) — window ends at 24:00
	// 21:30+ would cross midnight
	const MAX_START_IDX = 42;
	const SLOT_INDEX = new Map(SLOTS.map((s, i) => [s, i]));

	type Day = { dateStr: string; label: string; sub: string };

	let {
		days,
		selectedSlot,
		onselect
	}: {
		days: Day[];
		selectedSlot: string | null;
		onselect: (slot: string | null) => void;
	} = $props();

	function slotKey(dateStr: string, time: string): string {
		return `${dateStr}T${time}`;
	}

	function isSelectable(time: string): boolean {
		return (SLOT_INDEX.get(time) ?? 0) <= MAX_START_IDX;
	}

	function isInWindow(dateStr: string, time: string): boolean {
		if (!selectedSlot) return false;
		const sepIdx = selectedSlot.indexOf('T');
		const selDate = selectedSlot.slice(0, sepIdx);
		const selTime = selectedSlot.slice(sepIdx + 1);
		if (selDate !== dateStr) return false;
		const selIdx = SLOT_INDEX.get(selTime) ?? -1;
		const thisIdx = SLOT_INDEX.get(time) ?? -1;
		return thisIdx >= selIdx && thisIdx <= selIdx + 5;
	}

	function isWindowStart(dateStr: string, time: string): boolean {
		return selectedSlot === slotKey(dateStr, time);
	}

	function onClick(dateStr: string, time: string) {
		if (!isSelectable(time)) return;
		const k = slotKey(dateStr, time);
		onselect(selectedSlot === k ? null : k);
	}

	function cellClass(dateStr: string, time: string, isHour: boolean, isLastDay: boolean): string {
		const selectable = isSelectable(time);
		const inWindow = isInWindow(dateStr, time);
		const isStart = isWindowStart(dateStr, time);

		let bg: string;
		if (isStart) bg = 'bg-primary';
		else if (inWindow) bg = 'bg-primary/60';
		else if (!selectable) bg = 'bg-muted/10';
		else bg = 'bg-muted/20 hover:bg-primary/20';

		return [
			'border-b border-r border-border transition-colors duration-75',
			bg,
			selectable ? 'cursor-pointer' : 'cursor-default',
			!selectable ? 'opacity-30' : '',
			isHour ? 'border-l' : '',
			isLastDay ? 'border-b-0' : ''
		]
			.filter(Boolean)
			.join(' ');
	}
</script>

<svelte:window onmousedown={() => {}} />

<div class="overflow-auto rounded-md border border-border p-1">
	<table
		class="border-collapse text-xs w-full"
		style="table-layout: fixed; min-width: 52rem; user-select: none;"
	>
		<thead class="sticky top-0 z-20">
			<tr>
				<th
					class="sticky left-0 z-30 bg-card border-b border-r border-border px-2 py-2 text-left font-normal text-muted-foreground"
					style="width: 5rem;"
				></th>
				{#each SLOTS as time}
					{@const isHour = time.endsWith(':00')}
					<th
						class="bg-card border-b border-r border-border text-center font-normal text-muted-foreground {isHour
							? 'border-l'
							: ''}"
						style="padding: 0.25rem 0;"
					>
						{#if isHour}<span class="text-[9px]">{time.slice(0, 2)}</span>{/if}
					</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each days as day, di}
				<tr>
					<td
						class="sticky left-0 z-10 bg-card border-r border-b border-border px-2 text-muted-foreground leading-tight {di ===
						days.length - 1
							? 'border-b-0'
							: ''}"
						style="padding-top: 0.35rem; padding-bottom: 0.35rem;"
					>
						<div class="font-semibold text-foreground text-[11px]">{day.label}</div>
						<div class="text-[10px]">{day.sub}</div>
					</td>
					{#each SLOTS as time}
						{@const isHour = time.endsWith(':00')}
						<td
							class={cellClass(day.dateStr, time, isHour, di === days.length - 1)}
							style="height: 2rem;"
							onclick={() => onClick(day.dateStr, time)}
						></td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>
