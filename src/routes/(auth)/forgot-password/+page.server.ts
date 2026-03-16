import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ request, locals: { supabase }, url }) => {
		const data = await request.formData();
		const email = (data.get('email') as string)?.trim().toLowerCase();
		if (!email) return fail(400, { error: 'Email is required.' });

		const redirectTo = `${url.origin}/auth/callback?next=/reset-password`;

		const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo });
		if (error) return fail(400, { error: error.message });

		return { success: true };
	}
};
