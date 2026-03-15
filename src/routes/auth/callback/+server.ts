import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	const code = url.searchParams.get('code');
	const token_hash = url.searchParams.get('token_hash');
	const type = url.searchParams.get('type');
	const next = url.searchParams.get('next') ?? '/dashboard';

	if (code) {
		await supabase.auth.exchangeCodeForSession(code);
	} else if (token_hash && type) {
		await supabase.auth.verifyOtp({ token_hash, type: type as any });
	}

	// Link team_members row to the newly authenticated user
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

	redirect(303, next);
};
