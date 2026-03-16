import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

/** Link the authenticated user to their team_members invite row.
 *  Does NOT activate — activation happens in /register after the user
 *  sets their username and password. */
export const POST: RequestHandler = async ({ locals: { supabase } }) => {
	const {
		data: { user }
	} = await supabase.auth.getUser();

	if (user?.email) {
		await supabaseAdmin
			.from('team_members')
			.update({ user_id: user.id })
			.eq('invite_email', user.email)
			.eq('status', 'invited');
	}

	return json({ ok: true });
};
