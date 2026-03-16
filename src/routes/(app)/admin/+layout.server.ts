import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ parent }) => {
	const { profile } = await parent();
	if (profile?.role !== 'admin') redirect(303, '/dashboard');
	return {};
};
