<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData } from './$types';
	import PasswordInput from '$lib/components/PasswordInput.svelte';

	let { form }: { form: ActionData } = $props();
	let loading = $state(false);
</script>

<div class="min-h-screen flex items-center justify-center bg-background px-4">
	<div class="w-full max-w-sm space-y-6">
		<div class="text-center space-y-1">
			<h1 class="text-2xl font-bold tracking-tight">Set new password</h1>
			<p class="text-sm text-muted-foreground">Choose a strong password for your account.</p>
		</div>

		<form
			method="POST"
			use:enhance={() => {
				loading = true;
				return async ({ update }) => {
					loading = false;
					await update();
				};
			}}
			class="space-y-4"
		>
			{#if form?.error}
				<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{form.error}</p>
			{/if}

			<div class="space-y-1.5">
				<label class="text-sm font-medium" for="password">New password</label>
				<PasswordInput id="password" name="password" required minlength={8} autocomplete="new-password" />
			</div>

			<div class="space-y-1.5">
				<label class="text-sm font-medium" for="confirm">Confirm password</label>
				<PasswordInput id="confirm" name="confirm" required minlength={8} autocomplete="new-password" />
			</div>

			<button
				type="submit"
				disabled={loading}
				class="w-full py-2 px-4 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
			>
				{loading ? 'Saving…' : 'Save password'}
			</button>
		</form>
	</div>
</div>
