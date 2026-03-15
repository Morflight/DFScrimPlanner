import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { user } = await safeGetSession();

	const { data: availabilities } = await supabase
		.from('availabilities')
		.select('id, starts_at, ends_at')
		.eq('user_id', user!.id)
		.gte('ends_at', new Date().toISOString())
		.order('starts_at');

	return { availabilities: availabilities ?? [] };
};

export const actions: Actions = {
	add: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const startsAt = data.get('starts_at') as string;
		const endsAt = data.get('ends_at') as string;

		if (!startsAt || !endsAt) return fail(400, { error: 'Both start and end time are required.' });

		const start = new Date(startsAt);
		const end = new Date(endsAt);

		if (isNaN(start.getTime()) || isNaN(end.getTime()))
			return fail(400, { error: 'Invalid date/time values.' });

		if (end.getTime() - start.getTime() < 3 * 3_600_000)
			return fail(400, { error: 'Availability window must be at least 3 hours.' });

		const { error } = await supabase
			.from('availabilities')
			.insert({ user_id: user.id, starts_at: start.toISOString(), ends_at: end.toISOString() });

		if (error) return fail(500, { error: error.message });
		return {};
	},

	remove: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const id = data.get('id') as string;

		const { error } = await supabase
			.from('availabilities')
			.delete()
			.eq('id', id)
			.eq('user_id', user.id);

		if (error) return fail(500, { error: error.message });
		return {};
	},

	save: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const formData = await request.formData();
		const rangesJson = formData.get('ranges_json') as string;

		let ranges: { starts_at: string; ends_at: string }[];
		try {
			ranges = JSON.parse(rangesJson);
			if (!Array.isArray(ranges)) throw new Error('Not an array');
		} catch {
			return fail(400, { error: 'Invalid availability data.' });
		}

		// Replace all future availabilities with the new set
		const { error: delError } = await supabase
			.from('availabilities')
			.delete()
			.eq('user_id', user.id)
			.gte('ends_at', new Date().toISOString());

		if (delError) return fail(500, { error: delError.message });

		if (ranges.length > 0) {
			const { error: insertError } = await supabase
				.from('availabilities')
				.insert(ranges.map((r) => ({ user_id: user.id, starts_at: r.starts_at, ends_at: r.ends_at })));
			if (insertError) return fail(500, { error: insertError.message });
		}

		return { success: true };
	}
};
