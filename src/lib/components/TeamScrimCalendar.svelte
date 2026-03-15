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

	// Last valid scrim start: 21:00 (index 42) — window ends at 24:00
	const MAX_START_IDX = 42;
	const SLOT_INDEX = new Map(SLOTS.map((s, i) => [s, i]));

	type Day = { dateStr: string; label: string; sub: string };
	type Team = { id: string; name: string; slotSet: Set<string> };

	let {
		days,
		teams,
		selectedSlot,
		onselect,
		// 0 = use teams.length (all selected teams). Set to 1+ to override.
		threshold = 0,
		// When true, only slots where all 6 window slots meet the threshold are clickable.
		restrictToAvailable = false,
		// Label word for legend entries, e.g. 'team' or 'member'
		entryLabel = 'team'
	}: {
		days: Day[];
		teams: Team[];
		selectedSlot: string | null;
		onselect: (slot: string | null) => void;
		threshold?: number;
		restrictToAvailable?: boolean;
		entryLabel?: string;
	} = $props();

	// Effective overlap threshold
	const effectiveThreshold = $derived(threshold > 0 ? threshold : Math.max(1, teams.length));

	function slotKey(dateStr: string, time: string): string {
		return `${dateStr}T${time}`;
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

	// Count how many teams are available at each slot
	const overlapMap = $derived.by(() => {
		const map = new Map<string, number>();
		for (const day of days) {
			for (const t of SLOTS) {
				const k = slotKey(day.dateStr, t);
				map.set(k, teams.reduce((n, team) => n + (team.slotSet.has(k) ? 1 : 0), 0));
			}
		}
		return map;
	});

	// All slots in a ≥6-slot contiguous run meeting the effective threshold
	const scrimSlots = $derived.by(() => {
		const set = new Set<string>();
		if (teams.length === 0) return set;
		for (const day of days) {
			const keys = SLOTS.map((t) => slotKey(day.dateStr, t));
			let run = -1;
			for (let i = 0; i <= keys.length; i++) {
				if (i < keys.length && (overlapMap.get(keys[i]) ?? 0) >= effectiveThreshold) {
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

	// Valid START slots: index ≤ MAX_START_IDX and all 6 window slots are in scrimSlots
	const validStartSlots = $derived.by(() => {
		const set = new Set<string>();
		if (teams.length === 0) return set;
		for (const day of days) {
			const keys = SLOTS.map((t) => slotKey(day.dateStr, t));
			for (let i = 0; i <= MAX_START_IDX; i++) {
				let ok = true;
				for (let j = i; j <= i + 5; j++) {
					if (!scrimSlots.has(keys[j])) {
						ok = false;
						break;
					}
				}
				if (ok) set.add(keys[i]);
			}
		}
		return set;
	});

	function isSelectable(dateStr: string, time: string): boolean {
		const idx = SLOT_INDEX.get(time) ?? 0;
		if (idx > MAX_START_IDX) return false;
		if (restrictToAvailable) return validStartSlots.has(slotKey(dateStr, time));
		return true;
	}

	function onClick(dateStr: string, time: string) {
		if (!isSelectable(dateStr, time)) return;
		const k = slotKey(dateStr, time);
		onselect(selectedSlot === k ? null : k);
	}

	function overlapBg(k: string): string {
		if (teams.length === 0) return '';
		if (scrimSlots.has(k)) return 'bg-green-500/30';
		if ((overlapMap.get(k) ?? 0) >= effectiveThreshold) return 'bg-green-950/60';
		return '';
	}

	function cellClass(dateStr: string, time: string, isHour: boolean, isLastDay: boolean): string {
		const selectable = isSelectable(dateStr, time);
		const inWindow = isInWindow(dateStr, time);
		const isStart = isWindowStart(dateStr, time);
		const k = slotKey(dateStr, time);
		const idx = SLOT_INDEX.get(time) ?? 0;
		const pastMidnight = idx > MAX_START_IDX;

		let bg: string;
		if (isStart) bg = 'bg-primary';
		else if (inWindow) bg = 'bg-primary/60';
		else bg = overlapBg(k);

		return [
			'border-b border-r border-border transition-colors duration-75',
			bg,
			selectable ? 'cursor-pointer' : 'cursor-default',
			// Dim slots past 21:00 or (in restricted mode) outside available zones
			pastMidnight || (restrictToAvailable && !scrimSlots.has(k) && !inWindow && !isStart)
				? 'opacity-30'
				: '',
			isHour ? 'border-l' : '',
			isLastDay ? 'border-b-0' : ''
		]
			.filter(Boolean)
			.join(' ');
	}

	// Legend label for the scrim-ready indicator
	const scrimReadyLabel = $derived(
		effectiveThreshold >= teams.length && teams.length > 1
			? `all ${entryLabel}s available (scrim-ready)`
			: `≥${effectiveThreshold} ${entryLabel}${effectiveThreshold !== 1 ? 's' : ''} available (scrim-ready)`
	);
</script>

<!-- Legend -->
<div class="flex flex-wrap items-center gap-x-5 gap-y-1 mb-2 text-xs text-muted-foreground">
	{#each teams as team, i}
		<div class="flex items-center gap-1.5">
			<span class="inline-block w-4 h-[3px] rounded-full {PALETTE[i % PALETTE.length]}"></span>
			<span>{team.name}</span>
		</div>
	{/each}
	{#if teams.length > 0}
		<span class="text-muted-foreground/40">·</span>
		<div class="flex items-center gap-1.5">
			<span class="inline-block w-4 h-3 rounded-sm bg-green-500/30 border border-green-500/20"></span>
			<span>{scrimReadyLabel}</span>
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
							class={cellClass(day.dateStr, time, isHour, di === days.length - 1)}
							style="height: 2rem; padding: 2px 1px;"
							onclick={() => onClick(day.dateStr, time)}
						>
							{#if teams.length > 0}
								<div class="flex flex-col justify-evenly h-full">
									{#each teams as team, ti}
										<div
											class="h-[3px] rounded-full {PALETTE[ti % PALETTE.length]} {team.slotSet.has(k)
												? ''
												: 'opacity-0'}"
										></div>
									{/each}
								</div>
							{/if}
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>
