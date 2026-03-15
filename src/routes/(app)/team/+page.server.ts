import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { user } = await safeGetSession();

	// Check if user leads a team
	const { data: ledTeam } = await supabase
		.from('teams')
		.select('id, name, leader_id, created_at')
		.eq('leader_id', user!.id)
		.maybeSingle();

	// Check if user is a member of a team
	const { data: membership } = await supabase
		.from('team_members')
		.select('team_id, status, teams(id, name, leader_id)')
		.eq('user_id', user!.id)
		.eq('status', 'active')
		.maybeSingle();

	const team = ledTeam ?? (membership?.teams as any) ?? null;
	const isLeader = !!ledTeam;

	let members: any[] = [];
	let pendingInvites: any[] = [];

	if (team) {
		const { data: memberRows } = await supabase
			.from('team_members')
			.select('id, user_id, invite_email, status, invited_at, activated_at, profiles(username, timezone)')
			.eq('team_id', team.id);
		members = (memberRows ?? []).filter((m: any) => m.status === 'active');
		pendingInvites = (memberRows ?? []).filter((m: any) => m.status === 'invited');
	}

	return { team, isLeader, members, pendingInvites };
};

export const actions: Actions = {
	'create-team': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const name = (data.get('name') as string)?.trim();
		if (!name || name.length < 2) return fail(400, { error: 'Team name must be at least 2 characters.' });

		// Check user doesn't already lead a team
		const { data: existing } = await supabase
			.from('teams')
			.select('id')
			.eq('leader_id', user.id)
			.maybeSingle();
		if (existing) return fail(400, { error: 'You already lead a team.' });

		const { error } = await supabase.from('teams').insert({ name, leader_id: user.id });
		if (error) return fail(500, { error: error.message });

		// Update role to leader
		await supabase.from('profiles').update({ role: 'leader' }).eq('id', user.id);

		redirect(303, '/team');
	},

	'invite-member': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const email = (data.get('email') as string)?.trim().toLowerCase();
		if (!email) return fail(400, { inviteError: 'Email is required.' });

		// Must be a leader
		const { data: team } = await supabase
			.from('teams')
			.select('id')
			.eq('leader_id', user.id)
			.maybeSingle();
		if (!team) return fail(403, { inviteError: 'Only team leaders can invite members.' });

		// Don't re-invite same email
		const { data: existing } = await supabase
			.from('team_members')
			.select('id')
			.eq('team_id', team.id)
			.eq('invite_email', email)
			.maybeSingle();
		if (existing) return fail(400, { inviteError: 'This email has already been invited.' });

		// Create the team_members row first
		const { error: memberError } = await supabase.from('team_members').insert({
			team_id: team.id,
			invite_email: email,
			invite_token: crypto.randomUUID(),
			status: 'invited'
		});
		if (memberError) return fail(500, { inviteError: memberError.message });

		// Send the invite via Supabase Auth
		const { error: inviteError } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
			redirectTo: `${process.env.PUBLIC_SITE_URL ?? 'https://dfscrimplanner.local.com'}/auth/callback`
		});
		if (inviteError) {
			// Clean up the team_members row if invite failed
			await supabase.from('team_members').delete().eq('team_id', team.id).eq('invite_email', email);
			return fail(500, { inviteError: inviteError.message });
		}

		return { inviteSuccess: true };
	},

	'remove-member': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const memberId = data.get('member_id') as string;

		// Must be leader of this team
		const { data: team } = await supabase
			.from('teams')
			.select('id')
			.eq('leader_id', user.id)
			.maybeSingle();
		if (!team) return fail(403, { error: 'Only team leaders can remove members.' });

		const { error } = await supabase
			.from('team_members')
			.delete()
			.eq('id', memberId)
			.eq('team_id', team.id);
		if (error) return fail(500, { error: error.message });

		return {};
	}
};
