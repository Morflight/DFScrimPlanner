import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	const code = url.searchParams.get('code');
	const token_hash = url.searchParams.get('token_hash');
	const type = url.searchParams.get('type');
	const next = url.searchParams.get('next');

	// Exchange the token for a session — this overwrites any existing session cookies.
	if (code) {
		const { error } = await supabase.auth.exchangeCodeForSession(code);
		if (error) redirect(303, '/login');
	} else if (token_hash && type) {
		const { error } = await supabase.auth.verifyOtp({ token_hash, type: type as any });
		if (error) redirect(303, '/login');
	}

	const {
		data: { user }
	} = await supabase.auth.getUser();

	if (!user) redirect(303, '/login');

	// Link team_members row to the newly authenticated user (only for invite flow)
	if (user.email) {
		await supabaseAdmin
			.from('team_members')
			.update({ user_id: user.id, status: 'active', activated_at: new Date().toISOString() })
			.eq('invite_email', user.email)
			.eq('status', 'invited');
	}

	// Route based on flow type
	if (next) {
		redirect(303, next);
	} else if (type === 'recovery') {
		redirect(303, '/reset-password');
	} else if (type === 'invite') {
		redirect(303, '/register');
	} else {
		redirect(303, '/dashboard');
	}
};
