<script lang="ts">
	let {
		weekLabel,
		weekOffset,
		onnavigate
	}: {
		weekLabel: string;
		weekOffset: number;
		onnavigate: (delta: number) => void;
	} = $props();
</script>

<div class="flex items-center gap-3">
	<button
		onclick={() => onnavigate(-1)}
		class="px-2 py-1 rounded border border-border text-sm text-muted-foreground hover:text-foreground hover:bg-muted/40 transition-colors"
	>
		&larr; Prev
	</button>
	<span class="text-sm font-medium min-w-[10rem] text-center">{weekLabel}</span>
	<button
		onclick={() => onnavigate(1)}
		class="px-2 py-1 rounded border border-border text-sm text-muted-foreground hover:text-foreground hover:bg-muted/40 transition-colors"
	>
		Next &rarr;
	</button>
	{#if weekOffset !== 0}
		<button
			onclick={() => onnavigate(-weekOffset)}
			class="text-xs text-muted-foreground hover:text-foreground transition-colors"
		>
			Today
		</button>
	{/if}
</div>
