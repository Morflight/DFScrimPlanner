import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const actions: Actions = {
	default: async ({ request }) => {
		const data = await request.formData();
		const email = (data.get('email') as string)?.trim().toLowerCase();
		if (!email) return fail(400, { error: 'Email is required.' });

		// Check if user exists before attempting reset
		const { data: users, error: lookupError } = await supabaseAdmin.auth.admin.listUsers();
		const userExists = !lookupError && users.users.some((u) => u.email === email);

		if (!userExists) {
			console.warn(`[forgot-password] No account found for email: ${email}`);
			// Return success to prevent email enumeration on the client side
			return { success: true };
		}

		const siteUrl = process.env.PUBLIC_SITE_URL ?? 'https://dfscrimplanner.local.com';
		const redirectTo = `${siteUrl}/auth/callback?next=/reset-password`;

		const { error } = await supabaseAdmin.auth.resetPasswordForEmail(email, { redirectTo });
		if (error) {
			console.error(`[forgot-password] Failed to send reset email to ${email}:`, error.message);
			return fail(400, { error: error.message });
		}

		console.log(`[forgot-password] Reset email sent to ${email}`);
		return { success: true };
	}
};
