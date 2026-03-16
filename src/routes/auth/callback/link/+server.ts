import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const POST: RequestHandler = async ({ locals: { supabase } }) => {
	const {
		data: { user }
	} = await supabase.auth.getUser();

	if (user?.email) {
		await supabaseAdmin
			.from('team_members')
			.update({ user_id: user.id, status: 'active', activated_at: new Date().toISOString() })
			.eq('invite_email', user.email)
			.eq('status', 'invited');
	}

	return json({ ok: true });
};
