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
		onchange
	}: {
		days: Day[];
		selectedSlots: Set<string>;
		onchange: (slots: Set<string>) => void;
	} = $props();

	let isDragging = $state(false);
	let dragMode = $state<'select' | 'deselect'>('select');

	function slotKey(dateStr: string, time: string): string {
		return `${dateStr}T${time}`;
	}

	function onMouseDown(k: string, e: MouseEvent) {
		e.preventDefault();
		isDragging = true;
		dragMode = selectedSlots.has(k) ? 'deselect' : 'select';
		applySlot(k);
	}

	function onMouseEnter(k: string) {
		if (!isDragging) return;
		applySlot(k);
	}

	function applySlot(k: string) {
		const next = new Set(selectedSlots);
		if (dragMode === 'select') next.add(k);
		else next.delete(k);
		onchange(next);
	}
</script>

<svelte:window onmouseup={() => (isDragging = false)} />

<div class="overflow-auto rounded-md border border-border" style="max-height: 65vh;">
	<table class="border-collapse text-xs w-full" style="user-select: none;">
		<thead class="sticky top-0 z-20">
			<tr>
				<th
					class="sticky left-0 z-30 bg-card border-b border-r border-border w-14 px-2 py-2 text-left font-normal text-muted-foreground"
				></th>
				{#each days as day}
					<th
						class="bg-card border-b border-r border-border last:border-r-0 px-1 py-2 text-center min-w-[4.5rem]"
					>
						<div class="font-semibold text-foreground">{day.label}</div>
						<div class="text-[10px] text-muted-foreground mt-0.5">{day.sub}</div>
					</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each SLOTS as time}
				{@const isHour = time.endsWith(':00')}
				<tr>
					<td
						class="sticky left-0 z-10 bg-card border-r border-b border-border px-2 text-right text-muted-foreground leading-none w-14"
						class:border-t={isHour}
						style="height: 1.375rem;"
					>
						{#if isHour}<span class="text-[11px]">{time}</span>{/if}
					</td>
					{#each days as day, di}
						{@const k = slotKey(day.dateStr, time)}
						{@const selected = selectedSlots.has(k)}
						<td
							class="border-b border-r border-border cursor-pointer transition-colors duration-75 {selected
								? 'bg-primary hover:bg-primary/80'
								: 'bg-muted hover:bg-primary/20'} {isHour ? 'border-t' : ''} {di === days.length - 1 ? 'border-r-0' : ''}"
							style="height: 1.375rem;"
							onmousedown={(e) => onMouseDown(k, e)}
							onmouseenter={() => onMouseEnter(k)}
						></td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>
