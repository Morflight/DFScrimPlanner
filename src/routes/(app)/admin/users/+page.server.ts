import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const load: PageServerLoad = async () => {
	const { data: users } = await supabaseAdmin.auth.admin.listUsers();
	const userIds = (users?.users ?? []).map((u) => u.id);

	const { data: profiles } = userIds.length
		? await supabaseAdmin.from('profiles').select('id, username, timezone, role').in('id', userIds)
		: { data: [] };

	const profileMap = new Map((profiles ?? []).map((p) => [p.id, p]));

	const list = (users?.users ?? []).map((u) => ({
		id: u.id,
		email: u.email ?? '',
		created_at: u.created_at,
		last_sign_in_at: u.last_sign_in_at ?? null,
		username: profileMap.get(u.id)?.username ?? null,
		role: profileMap.get(u.id)?.role ?? 'player'
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

		if (!email) return fail(400, { createError: 'Email is required.' });
		if (!VALID_ROLES.includes(role)) return fail(400, { createError: 'Invalid role.' });

		// Invite via Supabase Auth — sends a password-setup email
		const { error } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
			redirectTo: `${url.origin}/auth/callback`,
			data: { initial_role: role }
		});
		if (error) return fail(400, { createError: error.message });

		return { createSuccess: true };
	}
};
