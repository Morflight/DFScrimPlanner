import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { findTeamsForSlot, findCommonSlots } from '$lib/utils/slot-matching';

export const load: PageServerLoad = async ({ locals: { supabase } }) => {
	// Load all teams with their members' availability windows (next 14 days)
	const horizon = new Date(Date.now() + 14 * 24 * 3_600_000).toISOString();
	const now = new Date().toISOString();

	const { data: teams } = await supabase
		.from('teams')
		.select('id, name, team_members(user_id)');

	// Load all active availabilities within the next 14 days
	const { data: allWindows } = await supabase
		.from('availabilities')
		.select('user_id, starts_at, ends_at')
		.gte('ends_at', now)
		.lte('starts_at', horizon);

	const windowsByUser = new Map<string, { starts_at: string; ends_at: string }[]>();
	for (const w of allWindows ?? []) {
		const list = windowsByUser.get(w.user_id) ?? [];
		list.push({ starts_at: w.starts_at, ends_at: w.ends_at });
		windowsByUser.set(w.user_id, list);
	}

	// Aggregate per team: union of all member windows
	const teamsWithWindows = (teams ?? []).map((team: any) => {
		const memberIds: string[] = (team.team_members ?? [])
			.map((m: any) => m.user_id)
			.filter(Boolean);
		const windows = memberIds.flatMap((uid) => windowsByUser.get(uid) ?? []);
		return { id: team.id, name: team.name, windows };
	});

	return { teams: teamsWithWindows };
};

export const actions: Actions = {
	'time-first': async ({ request, locals: { supabase } }) => {
		const data = await request.formData();
		const slotStartIso = data.get('slot_start') as string;
		if (!slotStartIso) return fail(400, { timeFirstError: 'Please select a time.' });

		const slotStart = new Date(slotStartIso);
		if (isNaN(slotStart.getTime())) return fail(400, { timeFirstError: 'Invalid time.' });

		const horizon = new Date(Date.now() + 14 * 24 * 3_600_000).toISOString();
		const now = new Date().toISOString();

		const { data: teams } = await supabase.from('teams').select('id, name, team_members(user_id)');
		const { data: allWindows } = await supabase
			.from('availabilities')
			.select('user_id, starts_at, ends_at')
			.gte('ends_at', now)
			.lte('starts_at', horizon);

		const windowsByUser = new Map<string, { starts_at: string; ends_at: string }[]>();
		for (const w of allWindows ?? []) {
			const list = windowsByUser.get(w.user_id) ?? [];
			list.push({ starts_at: w.starts_at, ends_at: w.ends_at });
			windowsByUser.set(w.user_id, list);
		}

		const teamsWithWindows = (teams ?? []).map((team: any) => {
			const memberIds: string[] = (team.team_members ?? [])
				.map((m: any) => m.user_id)
				.filter(Boolean);
			return { id: team.id, name: team.name, windows: memberIds.flatMap((uid) => windowsByUser.get(uid) ?? []) };
		});

		const available = findTeamsForSlot(teamsWithWindows, slotStart);
		return { timeFirstResults: available, slotStart: slotStartIso };
	},

	'teams-first': async ({ request, locals: { supabase } }) => {
		const data = await request.formData();
		const teamAId = data.get('team_a') as string;
		const teamBId = data.get('team_b') as string;

		if (!teamAId || !teamBId) return fail(400, { teamsFirstError: 'Select two teams.' });
		if (teamAId === teamBId) return fail(400, { teamsFirstError: 'Select two different teams.' });

		const now = new Date().toISOString();
		const horizon = new Date(Date.now() + 14 * 24 * 3_600_000).toISOString();

		const getWindows = async (teamId: string) => {
			const { data: members } = await supabase
				.from('team_members')
				.select('user_id')
				.eq('team_id', teamId)
				.eq('status', 'active')
				.not('user_id', 'is', null);

			const userIds = (members ?? []).map((m: any) => m.user_id);
			if (!userIds.length) return [];

			const { data: windows } = await supabase
				.from('availabilities')
				.select('starts_at, ends_at')
				.in('user_id', userIds)
				.gte('ends_at', now)
				.lte('starts_at', horizon);

			return windows ?? [];
		};

		const [teamAWindows, teamBWindows] = await Promise.all([getWindows(teamAId), getWindows(teamBId)]);
		const slots = findCommonSlots(teamAWindows, teamBWindows);

		return { teamsFirstResults: slots.map((s) => ({ starts_at: s.starts_at.toISOString() })) };
	},

	'create-scrim': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const startsAt = data.get('starts_at') as string;
		const teamAId = data.get('team_a') as string;
		const teamBId = data.get('team_b') as string;

		if (!startsAt || !teamAId || !teamBId) return fail(400, { error: 'Missing fields.' });

		const { data: scrim, error: scrimError } = await supabase
			.from('scrims')
			.insert({ organizer_id: user.id, starts_at: startsAt, status: 'proposed' })
			.select('id')
			.single();

		if (scrimError || !scrim) return fail(500, { error: scrimError?.message ?? 'Failed to create scrim.' });

		const { error: teamsError } = await supabase.from('scrim_teams').insert([
			{ scrim_id: scrim.id, team_id: teamAId },
			{ scrim_id: scrim.id, team_id: teamBId }
		]);

		if (teamsError) return fail(500, { error: teamsError.message });

		return { scrimCreated: true };
	}
};
