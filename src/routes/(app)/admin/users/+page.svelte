<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();
	let creating = $state(false);
	let selectedRole = $state('player');

	function formatDate(iso: string | null) {
		if (!iso) return '—';
		return new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short' }).format(
			new Date(iso)
		);
	}
</script>

<div class="px-4 py-6 md:p-8 max-w-4xl space-y-8">
	<div>
		<h1 class="text-2xl font-bold tracking-tight">User Management</h1>
		<p class="text-sm text-muted-foreground mt-1">Create and view all registered users.</p>
	</div>

	<!-- Create user form -->
	<section class="border border-border rounded-lg p-4 space-y-4">
		<h2 class="text-sm font-semibold">Invite new user</h2>

		{#if form?.createError}
			<p class="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">{form.createError}</p>
		{/if}
		{#if form?.createSuccess}
			<p class="text-sm text-green-600 bg-green-500/10 px-3 py-2 rounded-md">
				Invite sent — user will receive a password-setup email.
			</p>
		{/if}

		<form
			method="POST"
			action="?/create-user"
			use:enhance={() => {
				creating = true;
				return async ({ update }) => {
					creating = false;
					await update();
				};
			}}
			class="flex flex-wrap gap-2 items-end"
		>
			<div class="space-y-1">
				<label class="text-xs font-medium" for="email">Email</label>
				<input
					id="email"
					name="email"
					type="email"
					required
					placeholder="user@example.com"
					class="px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring w-64"
				/>
			</div>

			<div class="space-y-1">
				<label class="text-xs font-medium" for="role">Role</label>
				<select
					id="role"
					name="role"
					bind:value={selectedRole}
					class="px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
				>
					<option value="player">Player</option>
					<option value="leader">Leader</option>
					<option value="filler">Filler</option>
					<option value="admin">Admin</option>
				</select>
			</div>

			{#if selectedRole === 'leader'}
				<div class="space-y-1">
					<label class="text-xs font-medium" for="team_name">Team name</label>
					<input
						id="team_name"
						name="team_name"
						type="text"
						required
						minlength="2"
						placeholder="e.g. Alpha Squad"
						class="px-3 py-2 border border-input rounded-md bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring w-48"
					/>
				</div>
			{/if}

			<button
				type="submit"
				disabled={creating}
				class="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
			>
				{creating ? 'Sending…' : 'Send invite'}
			</button>
		</form>
	</section>

	<!-- User list -->
	<section class="space-y-3">
		<h2 class="text-sm font-semibold text-muted-foreground uppercase tracking-wider">
			All users ({data.users.length})
		</h2>

		{#if data.users.length === 0}
			<p class="text-sm text-muted-foreground">No users yet.</p>
		{:else}
			<div class="border border-border rounded-lg overflow-hidden">
				<table class="w-full text-sm">
					<thead>
						<tr class="border-b border-border bg-muted/50">
							<th class="text-left px-4 py-2 font-medium text-muted-foreground">Email</th>
							<th class="text-left px-4 py-2 font-medium text-muted-foreground">Username</th>
							<th class="text-left px-4 py-2 font-medium text-muted-foreground">Role</th>
							<th class="text-left px-4 py-2 font-medium text-muted-foreground">Team</th>
							<th class="text-left px-4 py-2 font-medium text-muted-foreground">Last sign-in</th>
						</tr>
					</thead>
					<tbody>
						{#each data.users as u}
							<tr class="border-b border-border last:border-0 hover:bg-muted/30 transition-colors">
								<td class="px-4 py-2.5">{u.email}</td>
								<td class="px-4 py-2.5 text-muted-foreground">{u.username ?? '—'}</td>
								<td class="px-4 py-2.5">
									<span class="capitalize text-xs font-medium px-2 py-0.5 rounded-full bg-muted">
										{u.role}
									</span>
								</td>
								<td class="px-4 py-2.5 text-muted-foreground">{u.team ?? '—'}</td>
								<td class="px-4 py-2.5 text-muted-foreground text-xs">{formatDate(u.last_sign_in_at)}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</section>
</div>
