import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import { defaultWeekStart } from '$lib/utils/timezone';

export const load: PageServerLoad = async ({ locals: { safeGetSession } }) => {
	const { user } = await safeGetSession();
	// If no session, user followed a direct link — redirect to login
	if (!user) redirect(303, '/login');

	// Link team_members row to this user (sets user_id, keeps status='invited').
	// Activation happens in the form action after the user sets their password.
	if (user.email) {
		await supabaseAdmin
			.from('team_members')
			.update({ user_id: user.id })
			.eq('invite_email', user.email)
			.eq('status', 'invited');
	}

	return { defaultUsername: user.email?.split('@')[0] ?? '' };
};

export const actions: Actions = {
	default: async ({ request, locals: { supabase } }) => {
		const data = await request.formData();
		const username = (data.get('username') as string)?.trim();
		const timezone = data.get('timezone') as string;
		const password = data.get('password') as string;

		if (!username || username.length < 3)
			return fail(400, { error: 'Username must be at least 3 characters.', username });

		const {
			data: { user },
			error: userError
		} = await supabase.auth.getUser();
		if (!user || userError) return fail(401, { error: 'Not authenticated.' });

		// Set password
		const { error: pwError } = await supabase.auth.updateUser({ password });
		if (pwError) return fail(400, { error: pwError.message, username });

		// Update profile
		const week_starts_on = defaultWeekStart(timezone);
		const { error: profileError } = await supabase
			.from('profiles')
			.update({ username, timezone, week_starts_on })
			.eq('id', user.id);

		if (profileError) return fail(500, { error: profileError.message, username });

		// Activate team membership now that registration is complete
		await supabaseAdmin
			.from('team_members')
			.update({ status: 'active', activated_at: new Date().toISOString() })
			.eq('user_id', user.id)
			.eq('status', 'invited');

		redirect(303, '/dashboard');
	}
};
