<script lang="ts">
	import { Moon, Sun } from 'lucide-svelte';
	import { theme } from '$lib/stores/theme';
</script>

<button
	type="button"
	onclick={() => theme.toggle()}
	aria-label="Toggle dark mode"
	class="text-muted-foreground hover:text-foreground transition-colors"
>
	{#if $theme === 'dark'}
		<Sun size={14} />
	{:else}
		<Moon size={14} />
	{/if}
</button>
