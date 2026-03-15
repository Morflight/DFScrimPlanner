import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase } }) => {
	// Fetch all filler players with their upcoming availability
	const now = new Date().toISOString();
	const horizon = new Date(Date.now() + 14 * 24 * 3_600_000).toISOString();

	const { data: fillers } = await supabase
		.from('profiles')
		.select('id, username, timezone, availabilities(starts_at, ends_at)')
		.eq('role', 'filler');

	// Filter availability to next 14 days
	const result = (fillers ?? []).map((f: any) => ({
		...f,
		availabilities: (f.availabilities ?? []).filter(
			(a: any) => a.ends_at >= now && a.starts_at <= horizon
		)
	}));

	return { fillers: result };
};

export const actions: Actions = {
	'register-filler': async ({ locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const { error } = await supabase
			.from('profiles')
			.update({ role: 'filler' })
			.eq('id', user.id);

		if (error) return fail(500, { error: error.message });
		return { registered: true };
	},

	'unregister-filler': async ({ locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const { error } = await supabase
			.from('profiles')
			.update({ role: 'player' })
			.eq('id', user.id);

		if (error) return fail(500, { error: error.message });
		return { unregistered: true };
	}
};
