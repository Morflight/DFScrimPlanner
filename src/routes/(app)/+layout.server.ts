import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals: { safeGetSession, supabase } }) => {
	const { session, user } = await safeGetSession();
	if (!session) redirect(303, '/login');

	const { data: profile } = await supabase
		.from('profiles')
		.select('*')
		.eq('id', user!.id)
		.single();

	return { profile };
};
