import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { safeGetSession } }) => {
	const { user } = await safeGetSession();
	if (!user) redirect(303, '/login');
	return {};
};

export const actions: Actions = {
	default: async ({ request, locals: { supabase } }) => {
		const data = await request.formData();
		const password = data.get('password') as string;
		const confirm = data.get('confirm') as string;

		if (!password || password.length < 8)
			return fail(400, { error: 'Password must be at least 8 characters.' });
		if (password !== confirm)
			return fail(400, { error: 'Passwords do not match.' });

		const { error } = await supabase.auth.updateUser({ password });
		if (error) return fail(400, { error: error.message });

		redirect(303, '/dashboard');
	}
};
