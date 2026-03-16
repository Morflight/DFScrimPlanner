import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	const code = url.searchParams.get('code');
	const token_hash = url.searchParams.get('token_hash');
	const type = url.searchParams.get('type');
	const next = url.searchParams.get('next');

	// Invalidate any existing session before processing an invite or recovery link.
	// This ensures the incoming token always starts a clean, dedicated session and
	// a logged-in user who clicks someone else's invite (or their own reset link)
	// doesn't end up mixing sessions.
	await supabase.auth.signOut();

	if (code) {
		await supabase.auth.exchangeCodeForSession(code);
	} else if (token_hash && type) {
		await supabase.auth.verifyOtp({ token_hash, type: type as any });
	}

	const {
		data: { user }
	} = await supabase.auth.getUser();

	if (user?.email) {
		// Link team_members row to the newly authenticated user (only for invite flow)
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
