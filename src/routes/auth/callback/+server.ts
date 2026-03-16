import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	const code = url.searchParams.get('code');
	const next = url.searchParams.get('next');

	if (!code) redirect(303, '/login');

	// Exchange the PKCE code for a session.
	// This sets new session cookies via the setAll() callback in hooks.server.ts,
	// overwriting any existing session (e.g. if an admin was logged in).
	const { error } = await supabase.auth.exchangeCodeForSession(code);
	if (error) redirect(303, '/login');

	const {
		data: { user }
	} = await supabase.auth.getUser();

	if (!user) redirect(303, '/login');

	// For invite flow: link user_id on team_members (keeps status='invited'
	// until the user completes registration on /register).
	if (user.email) {
		await supabaseAdmin
			.from('team_members')
			.update({ user_id: user.id })
			.eq('invite_email', user.email)
			.eq('status', 'invited');
	}

	// Determine where to route.
	// Supabase doesn't pass `type` as a query param in PKCE flow, so we check
	// the user state to figure out the flow:
	// - No password set (invited user) → /register
	// - next param present → honor it (used by forgot-password)
	// - Otherwise → /dashboard

	if (next) {
		redirect(303, next);
	}

	// Check if user has completed registration (has a password / confirmed)
	const { data: profile } = await supabaseAdmin
		.from('profiles')
		.select('username')
		.eq('id', user.id)
		.single();

	// If username is still the email prefix (default from trigger), treat as
	// unregistered — send to /register to set username + password.
	const emailPrefix = user.email?.split('@')[0] ?? '';
	const needsRegistration = !profile || profile.username === emailPrefix;

	if (needsRegistration) {
		redirect(303, '/register');
	}

	redirect(303, '/dashboard');
};
