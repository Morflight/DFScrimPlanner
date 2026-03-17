import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

/** Checks whether currentUserId and targetUserId share a team (any direction). */
async function isTeammate(currentUserId: string, targetUserId: string): Promise<boolean> {
	const [{ data: ledByMe }, { data: myMemberships }] = await Promise.all([
		supabaseAdmin.from('teams').select('id').eq('leader_id', currentUserId),
		supabaseAdmin
			.from('team_members')
			.select('team_id')
			.eq('user_id', currentUserId)
			.eq('status', 'active')
	]);

	const myTeamIds = [
		...(ledByMe?.map((t) => t.id) ?? []),
		...(myMemberships?.map((m) => m.team_id) ?? [])
	];

	if (myTeamIds.length === 0) return false;

	const [{ data: targetLed }, { data: targetMemberships }] = await Promise.all([
		supabaseAdmin.from('teams').select('id').eq('leader_id', targetUserId).in('id', myTeamIds),
		supabaseAdmin
			.from('team_members')
			.select('id')
			.eq('user_id', targetUserId)
			.eq('status', 'active')
			.in('team_id', myTeamIds)
			.limit(1)
	]);

	return (targetLed?.length ?? 0) > 0 || (targetMemberships?.length ?? 0) > 0;
}

export const load: PageServerLoad = async ({ params, locals: { safeGetSession } }) => {
	const { user } = await safeGetSession();
	const targetUserId = params.userId;

	// Redirect to own availability page if editing self
	if (targetUserId === user!.id) redirect(303, '/availability');

	// Gate: must share a team with target user
	const teammate = await isTeammate(user!.id, targetUserId);
	if (!teammate) redirect(303, '/team');

	// Fetch target user's profile
	const { data: targetProfile } = await supabaseAdmin
		.from('profiles')
		.select('id, username, timezone')
		.eq('id', targetUserId)
		.single();

	if (!targetProfile) redirect(303, '/team');

	// Fetch target user's future availabilities
	const { data: availabilities } = await supabaseAdmin
		.from('availabilities')
		.select('id, starts_at, ends_at')
		.eq('user_id', targetUserId)
		.gte('ends_at', new Date().toISOString())
		.order('starts_at');

	// Find target user's team for scrim lookup
	const { data: targetLedTeam } = await supabaseAdmin
		.from('teams')
		.select('id')
		.eq('leader_id', targetUserId)
		.limit(1)
		.maybeSingle();
	let targetTeamId: string | null = targetLedTeam?.id ?? null;
	if (!targetTeamId) {
		const { data: targetMem } = await supabaseAdmin
			.from('team_members')
			.select('team_id')
			.eq('user_id', targetUserId)
			.eq('status', 'active')
			.limit(1)
			.maybeSingle();
		targetTeamId = targetMem?.team_id ?? null;
	}

	// Fetch non-cancelled scrims for target's team
	let scrims: { starts_at: string }[] = [];
	if (targetTeamId) {
		const { data: scrimData } = await supabaseAdmin
			.from('scrims')
			.select('starts_at, scrim_teams!inner(team_id)')
			.eq('scrim_teams.team_id', targetTeamId)
			.eq('status', 'confirmed')
			.gte('starts_at', new Date(Date.now() - 3 * 3_600_000).toISOString());
		scrims = (scrimData ?? []).map((s) => ({ starts_at: s.starts_at }));
	}

	return {
		targetProfile,
		availabilities: availabilities ?? [],
		scrims
	};
};

export const actions: Actions = {
	save: async ({ params, request, locals: { safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const targetUserId = params.userId;
		if (targetUserId === user.id)
			return fail(400, { error: 'Use /availability for your own calendar.' });

		// Re-verify permission on every write
		const teammate = await isTeammate(user.id, targetUserId);
		if (!teammate) return fail(403, { error: 'You are not a teammate of this user.' });

		const formData = await request.formData();
		const rangesJson = formData.get('ranges_json') as string;

		let ranges: { starts_at: string; ends_at: string }[];
		try {
			ranges = JSON.parse(rangesJson);
			if (!Array.isArray(ranges)) throw new Error('Not an array');
		} catch {
			return fail(400, { error: 'Invalid availability data.' });
		}

		// Replace all future availabilities for the target user
		const { error: delError } = await supabaseAdmin
			.from('availabilities')
			.delete()
			.eq('user_id', targetUserId)
			.gte('ends_at', new Date().toISOString());

		if (delError) return fail(500, { error: delError.message });

		if (ranges.length > 0) {
			const { error: insertError } = await supabaseAdmin.from('availabilities').insert(
				ranges.map((r) => ({
					user_id: targetUserId,
					starts_at: r.starts_at,
					ends_at: r.ends_at
				}))
			);
			if (insertError) return fail(500, { error: insertError.message });
		}

		return { success: true };
	}
};
