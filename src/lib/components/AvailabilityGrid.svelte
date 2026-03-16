<script lang="ts">
	const SLOTS: string[] = Array.from({ length: 48 }, (_, i) => {
		const h = Math.floor(i / 2);
		const m = i % 2 === 0 ? '00' : '30';
		return `${String(h).padStart(2, '0')}:${m}`;
	});

	type Day = { dateStr: string; label: string; sub: string };

	let {
		days,
		selectedSlots,
		onchange,
		readonly = false
	}: {
		days: Day[];
		selectedSlots: Set<string>;
		onchange: (slots: Set<string>) => void;
		readonly?: boolean;
	} = $props();

	let isDragging = $state(false);
	let dragMode = $state<'select' | 'deselect'>('select');

	function slotKey(dateStr: string, time: string): string {
		return `${dateStr}T${time}`;
	}

	function onMouseDown(k: string, e: MouseEvent) {
		if (readonly) return;
		e.preventDefault();
		isDragging = true;
		dragMode = selectedSlots.has(k) ? 'deselect' : 'select';
		applySlot(k);
	}

	function onMouseEnter(k: string) {
		if (readonly || !isDragging) return;
		applySlot(k);
	}

	function applySlot(k: string) {
		const next = new Set(selectedSlots);
		if (dragMode === 'select') next.add(k);
		else next.delete(k);
		onchange(next);
	}

	// For each selected slot, compute whether it belongs to a contiguous run ≥ 6 slots (3h).
	// 'scrim' = run is long enough to hold a scrim; 'short' = too short.
	const slotTypes = $derived.by(() => {
		const result = new Map<string, 'scrim' | 'short'>();

		for (const day of days) {
			// Collect indices of selected slots for this day, in order
			const selected: number[] = [];
			for (let i = 0; i < SLOTS.length; i++) {
				if (selectedSlots.has(slotKey(day.dateStr, SLOTS[i]))) selected.push(i);
			}

			// Walk contiguous runs (consecutive slot indices)
			let i = 0;
			while (i < selected.length) {
				let j = i;
				while (j + 1 < selected.length && selected[j + 1] === selected[j] + 1) j++;
				const type = j - i + 1 >= 6 ? 'scrim' : 'short';
				for (let k = i; k <= j; k++) {
					result.set(slotKey(day.dateStr, SLOTS[selected[k]]), type);
				}
				i = j + 1;
			}
		}

		return result;
	});

	function cellClass(k: string, isHour: boolean, isLastDay: boolean): string {
		const type = slotTypes.get(k);
		let bg: string;
		if (readonly) {
			if (type === 'scrim') bg = 'bg-blue-500 dark:bg-blue-600';
			else if (type === 'short') bg = 'bg-blue-200 dark:bg-blue-950';
			else bg = 'bg-zinc-100 dark:bg-zinc-800';
		} else {
			if (type === 'scrim') bg = 'bg-blue-500 hover:bg-blue-400 dark:bg-blue-600 dark:hover:bg-blue-500';
			else if (type === 'short') bg = 'bg-blue-200 hover:bg-blue-300 dark:bg-blue-950 dark:hover:bg-blue-900';
			else bg = 'bg-zinc-100 hover:bg-zinc-200 dark:bg-zinc-800 dark:hover:bg-zinc-700';
		}

		return [
			`border-b border-r border-border ${readonly ? 'cursor-default' : 'cursor-pointer'} transition-colors duration-75`,
			bg,
			isHour ? 'border-l' : '',
			isLastDay ? 'border-b-0' : ''
		]
			.filter(Boolean)
			.join(' ');
	}
</script>

<svelte:window onmouseup={() => (isDragging = false)} />

<div class="overflow-x-auto rounded-md border border-border p-1">
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
						{@const k = slotKey(day.dateStr, time)}
						<td
							class={cellClass(k, isHour, di === days.length - 1)}
							style="height: 2rem;"
							onmousedown={(e) => onMouseDown(k, e)}
							onmouseenter={() => onMouseEnter(k)}
						></td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>
