<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData } from './$types';

	let { form }: { form: ActionData } = $props();
	let loading = $state(false);
</script>

<div class="min-h-screen flex items-center justify-center bg-background px-4">
	<div class="w-full max-w-sm space-y-6">
		<div class="text-center space-y-1">
			<h1 class="text-2xl font-bold tracking-tight">Forgot password</h1>
			<p class="text-sm text-muted-foreground">We'll send you a link to reset your password.</p>
		</div>

		{#if form?.success}
			<div class="text-sm text-green-600 bg-green-500/10 px-3 py-2 rounded-md">
				Check your inbox — a reset link has been sent.
			</div>
		{:else}
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
					<label class="text-sm font-medium" for="email">Email</label>
					<input
						id="email"
						name="email"
						type="email"
						required
						autocomplete="email"
						placeholder="you@example.com"
						class="w-full px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
					/>
				</div>

				<button
					type="submit"
					disabled={loading}
					class="w-full py-2 px-4 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
				>
					{loading ? 'Sending…' : 'Send reset link'}
				</button>
			</form>
		{/if}

		<p class="text-center text-xs text-muted-foreground">
			<a href="/login" class="hover:text-foreground transition-colors">Back to sign in</a>
		</p>
	</div>
</div>
