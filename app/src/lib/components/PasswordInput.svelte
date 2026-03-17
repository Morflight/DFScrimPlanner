<script lang="ts">
	import { Eye, EyeOff } from 'lucide-svelte';

	let {
		id,
		name,
		required = false,
		minlength,
		autocomplete,
		placeholder,
		class: className = ''
	}: {
		id?: string;
		name: string;
		required?: boolean;
		minlength?: number;
		autocomplete?: string;
		placeholder?: string;
		class?: string;
	} = $props();

	let visible = $state(false);
</script>

<div class="relative">
	<input
		{id}
		{name}
		type={visible ? 'text' : 'password'}
		{required}
		{minlength}
		{autocomplete}
		{placeholder}
		class="w-full px-3 py-2 pr-9 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring {className}"
	/>
	<button
		type="button"
		onclick={() => (visible = !visible)}
		class="absolute inset-y-0 right-0 flex items-center px-2.5 text-muted-foreground hover:text-foreground transition-colors"
		aria-label={visible ? 'Hide password' : 'Show password'}
	>
		{#if visible}
			<EyeOff size={16} />
		{:else}
			<Eye size={16} />
		{/if}
	</button>
</div>
