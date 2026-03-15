<script lang="ts">
	const SLOTS: string[] = Array.from({ length: 48 }, (_, i) => {
		const h = Math.floor(i / 2);
		const m = i % 2 === 0 ? '00' : '30';
		return `${String(h).padStart(2, '0')}:${m}`;
	});

	const PALETTE = [
		'bg-blue-400',
		'bg-emerald-400',
		'bg-violet-400',
		'bg-amber-400',
		'bg-rose-400',
		'bg-cyan-400'
	];

	type Day = { dateStr: string; label: string; sub: string };
	type Member = { userId: string; username: string; slotSet: Set<string> };

	let { days, members }: { days: Day[]; members: Member[] } = $props();

	function slotKey(dateStr: string, time: string): string {
		return `${dateStr}T${time}`;
	}

	const overlapMap = $derived.by(() => {
		const map = new Map<string, number>();
		for (const day of days) {
			for (const t of SLOTS) {
				const k = slotKey(day.dateStr, t);
				map.set(k, members.reduce((n, m) => n + (m.slotSet.has(k) ? 1 : 0), 0));
			}
		}
		return map;
	});

	// Slots that are in a ≥6-slot (3h) contiguous run where 3+ members overlap
	const scrimSlots = $derived.by(() => {
		const set = new Set<string>();
		for (const day of days) {
			const keys = SLOTS.map((t) => slotKey(day.dateStr, t));
			let run = -1;
			for (let i = 0; i <= keys.length; i++) {
				if (i < keys.length && (overlapMap.get(keys[i]) ?? 0) >= 3) {
					if (run === -1) run = i;
				} else {
					if (run !== -1 && i - run >= 6) {
						for (let j = run; j < i; j++) set.add(keys[j]);
					}
					run = -1;
				}
			}
		}
		return set;
	});

	function overlapBg(k: string): string {
		const count = overlapMap.get(k) ?? 0;
		if (scrimSlots.has(k)) return 'bg-green-500/30'; // clear = scrim-ready ≥3h
		if (count >= 3) return 'bg-green-950/60'; // dark = 3+ overlap but <3h
		return '';
	}
</script>

<!-- Legend -->
<div class="flex flex-wrap items-center gap-x-5 gap-y-1 mb-2 text-xs text-muted-foreground">
	{#each members as member, i}
		<div class="flex items-center gap-1.5">
			<span class="inline-block w-4 h-[3px] rounded-full {PALETTE[i % PALETTE.length]}"></span>
			<span>{member.username}</span>
		</div>
	{/each}
	{#if members.length >= 3}
		<span class="text-muted-foreground/40">·</span>
		<div class="flex items-center gap-1.5">
			<span class="inline-block w-4 h-3 rounded-sm bg-green-950/60 border border-green-900/40"></span>
			<span>3+ overlap (&lt;3h)</span>
		</div>
		<div class="flex items-center gap-1.5">
			<span class="inline-block w-4 h-3 rounded-sm bg-green-500/30 border border-green-500/20"></span>
			<span>3+ overlap (scrim-ready)</span>
		</div>
	{/if}
</div>

<!-- Grid -->
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
						{@const k = slotKey(day.dateStr, time)}
						<td
							class="border-b border-r border-border {isHour ? 'border-l' : ''} {overlapBg(k)} {di ===
							days.length - 1
								? 'border-b-0'
								: ''}"
							style="height: 2rem; padding: 2px 1px;"
						>
							<div class="flex flex-col justify-evenly h-full">
								{#each members as member, mi}
									<div
										class="h-[3px] rounded-full {PALETTE[mi % PALETTE.length]} {member.slotSet.has(k)
											? ''
											: 'opacity-0'}"
									></div>
								{/each}
							</div>
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>
