import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const load: PageServerLoad = async () => {
	const { data: users } = await supabaseAdmin.auth.admin.listUsers();
	const userIds = (users?.users ?? []).map((u) => u.id);

	const [{ data: profiles }, { data: teams }] = await Promise.all([
		userIds.length
			? supabaseAdmin.from('profiles').select('id, username, timezone, role').in('id', userIds)
			: { data: [] },
		supabaseAdmin.from('teams').select('id, name, leader_id')
	]);

	const profileMap = new Map((profiles ?? []).map((p) => [p.id, p]));
	const teamByLeader = new Map((teams ?? []).map((t) => [t.leader_id, t.name]));

	const list = (users?.users ?? []).map((u) => ({
		id: u.id,
		email: u.email ?? '',
		created_at: u.created_at,
		last_sign_in_at: u.last_sign_in_at ?? null,
		username: profileMap.get(u.id)?.username ?? null,
		role: profileMap.get(u.id)?.role ?? 'player',
		team: teamByLeader.get(u.id) ?? null
	}));

	return { users: list };
};

const VALID_ROLES = ['player', 'leader', 'filler', 'admin'] as const;
type Role = (typeof VALID_ROLES)[number];

export const actions: Actions = {
	'create-user': async ({ request, url }) => {
		const data = await request.formData();
		const email = (data.get('email') as string)?.trim().toLowerCase();
		const role = (data.get('role') as string) as Role;
		const teamName = (data.get('team_name') as string)?.trim() ?? '';

		if (!email) return fail(400, { createError: 'Email is required.' });
		if (!VALID_ROLES.includes(role)) return fail(400, { createError: 'Invalid role.' });
		if (role === 'leader' && !teamName) return fail(400, { createError: 'Team name is required for leaders.' });
		if (teamName && teamName.length < 2) return fail(400, { createError: 'Team name must be at least 2 characters.' });

		// Check for duplicate before inviting
		const { data: authUsers } = await supabaseAdmin.auth.admin.listUsers();
		const alreadyExists = (authUsers?.users ?? []).some(
			(u) => u.email?.toLowerCase() === email
		);
		if (alreadyExists) return fail(400, { createError: 'A user with this email already exists.' });

		// Invite via Supabase Auth — sends a password-setup email
		const { data: invited, error } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
			redirectTo: `${process.env.PUBLIC_SITE_URL ?? 'https://dfscrimplanner.local.com'}/auth/callback`,
			data: { role }
		});
		if (error) return fail(400, { createError: error.message });

		// Create team immediately so the leader has one when they sign in
		if (role === 'leader' && invited?.user) {
			const { error: teamError } = await supabaseAdmin
				.from('teams')
				.insert({ name: teamName, leader_id: invited.user.id });
			if (teamError) return fail(500, { createError: `User invited but team creation failed: ${teamError.message}` });
		}

		return { createSuccess: true };
	}
};
