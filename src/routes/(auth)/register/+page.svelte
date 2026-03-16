<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData } from './$types';
	import PasswordInput from '$lib/components/PasswordInput.svelte';

	let { data, form }: { data: PageData; form: ActionData } = $props();
	let loading = $state(false);

	const timezones = Intl.supportedValuesOf('timeZone');
	const userTz = Intl.DateTimeFormat().resolvedOptions().timeZone;
</script>

<div class="min-h-screen flex items-center justify-center bg-background px-4">
	<div class="w-full max-w-sm space-y-6">
		<div class="text-center space-y-1">
			<h1 class="text-2xl font-bold tracking-tight">Complete your profile</h1>
			<p class="text-sm text-muted-foreground">You've been invited to join a team</p>
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
				<label class="text-sm font-medium" for="username">Username</label>
				<input
					id="username"
					name="username"
					type="text"
					required
					minlength="3"
					placeholder="YourGamertag"
					value={(form as any)?.username ?? ''}
					class="w-full px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
				/>
			</div>

			<div class="space-y-1.5">
				<label class="text-sm font-medium" for="timezone">Your timezone</label>
				<select
					id="timezone"
					name="timezone"
					class="w-full px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
				>
					{#each timezones as tz}
						<option value={tz} selected={tz === userTz}>{tz}</option>
					{/each}
				</select>
			</div>

			<div class="space-y-1.5">
				<label class="text-sm font-medium" for="password">Set a password</label>
				<PasswordInput id="password" name="password" required minlength={8} autocomplete="new-password" />
			</div>

			<button
				type="submit"
				disabled={loading}
				class="w-full py-2 px-4 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
			>
				{loading ? 'Saving…' : 'Complete registration'}
			</button>
		</form>
	</div>
</div>
