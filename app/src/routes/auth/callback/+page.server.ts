import { redirect } from '@sveltejs/kit';
import type { Actions } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const actions: Actions = {
	default: async ({ request, locals: { supabase } }) => {
		const data = await request.formData();
		const accessToken = data.get('access_token') as string;
		const refreshToken = data.get('refresh_token') as string;
		const type = data.get('type') as string;
		const next = data.get('next') as string;

		if (!accessToken || !refreshToken) redirect(303, '/login');

		// Set the session server-side — this properly writes httpOnly cookies
		// via the setAll() callback in hooks.server.ts, overwriting any
		// existing session (e.g. admin who sent the invite).
		const { error } = await supabase.auth.setSession({
			access_token: accessToken,
			refresh_token: refreshToken
		});

		if (error) redirect(303, '/login');

		const {
			data: { user }
		} = await supabase.auth.getUser();

		if (!user) redirect(303, '/login');

		// Link user_id on team_members (keeps status='invited' —
		// activation happens in /register after password is set).
		if (user.email) {
			await supabaseAdmin
				.from('team_members')
				.update({ user_id: user.id })
				.eq('invite_email', user.email)
				.eq('status', 'invited');
		}

		// Route based on flow type
		if (next) {
			redirect(303, next);
		} else if (type === 'invite' || type === 'signup') {
			redirect(303, '/register');
		} else if (type === 'recovery') {
			redirect(303, '/reset-password');
		} else {
			redirect(303, '/register');
		}
	}
};
