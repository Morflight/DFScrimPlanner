import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async () => ({});

export const actions: Actions = {
	'update-username': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		const data = await request.formData();
		const username = (data.get('username') as string | null)?.trim();

		if (!username) return fail(400, { error: 'Username cannot be empty.' });
		if (username.length > 32) return fail(400, { error: 'Username must be 32 characters or fewer.' });

		const { error } = await supabase
			.from('profiles')
			.update({ username })
			.eq('id', user!.id);

		if (error) return fail(500, { error: 'Failed to update username. Please try again.' });

		return { success: true, username };
	}
};
