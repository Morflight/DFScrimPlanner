import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { findTeamsForSlot } from '$lib/utils/slot-matching';
import { slotsFromWindow, alignToWeekStart } from '$lib/utils/timezone';
import { supabaseAdmin } from '$lib/server/supabase';

export const load: PageServerLoad = async ({ url, locals: { supabase, safeGetSession } }) => {
	const { user } = await safeGetSession();

	// Week offset from URL (0 = current week, 1 = next week, -1 = previous week)
	let weekOffset = parseInt(url.searchParams.get('week') ?? '0', 10) || 0;
	const explicitWeek = url.searchParams.has('week');

	// Viewer timezone for grid
	const { data: profile } = await supabase
		.from('profiles')
		.select('timezone, week_starts_on')
		.eq('id', user!.id)
		.single();
	const viewerTz = profile?.timezone ?? 'UTC';
	const weekStartDay = (profile?.week_starts_on ?? 'monday') as 'monday' | 'sunday';

	const now = new Date();
	const dateFmt = new Intl.DateTimeFormat('en-US', {
		timeZone: viewerTz,
		year: 'numeric',
		month: '2-digit',
		day: '2-digit'
	});
	const todayParts = dateFmt.formatToParts(now);
	const ty = todayParts.find((p) => p.type === 'year')?.value ?? '';
	const tm = todayParts.find((p) => p.type === 'month')?.value ?? '';
	const td = todayParts.find((p) => p.type === 'day')?.value ?? '';
	const todayStart = new Date(`${ty}-${tm}-${td}T00:00:00Z`);

	// Auto-detect: if no explicit week param, jump to the first week with availability
	const baseWeekStart = new Date(alignToWeekStart(`${ty}-${tm}-${td}`, weekStartDay) + 'T00:00:00Z');
	if (!explicitWeek) {
		const { data: nextAvail } = await supabaseAdmin
			.from('availabilities')
			.select('starts_at')
			.gte('ends_at', todayStart.toISOString())
			.order('starts_at', { ascending: true })
			.limit(1)
			.maybeSingle();

		if (nextAvail) {
			const earliestMs = new Date(nextAvail.starts_at).getTime();
			const diffDays = Math.floor((earliestMs - baseWeekStart.getTime()) / (24 * 3_600_000));
			if (diffDays >= 7) {
				weekOffset = Math.floor(diffDays / 7);
			}
		}
	}

	// Grid days: 7 days from week start + offset, in viewer's timezone
	const todayStr = `${ty}-${tm}-${td}`;
	const weekStartStr = alignToWeekStart(todayStr, weekStartDay);
	const start = new Date(weekStartStr + 'T00:00:00Z');
	start.setUTCDate(start.getUTCDate() + weekOffset * 7);

	const validDates = new Set<string>();
	const gridDays = Array.from({ length: 7 }, (_, i) => {
		const d = new Date(start);
		d.setUTCDate(start.getUTCDate() + i);
		const parts = dateFmt.formatToParts(d);
		const y = parts.find((p) => p.type === 'year')?.value ?? '';
		const mo = parts.find((p) => p.type === 'month')?.value ?? '';
		const dy = parts.find((p) => p.type === 'day')?.value ?? '';
		const dateStr = `${y}-${mo}-${dy}`;
		validDates.add(dateStr);
		return {
			dateStr,
			label: new Intl.DateTimeFormat('en-US', { timeZone: viewerTz, weekday: 'short' }).format(d),
			sub: new Intl.DateTimeFormat('en-US', {
				timeZone: viewerTz,
				month: 'short',
				day: 'numeric'
			}).format(d)
		};
	});

	const windowStart = start.toISOString();
	const windowEnd = new Date(start.getTime() + 7 * 24 * 3_600_000).toISOString();

	// ── Viewer's own team ────────────────────────────────────────────────────
	// Leader check first, then member check
	const { data: ledTeam } = await supabase
		.from('teams')
		.select('id, leader_id')
		.eq('leader_id', user!.id)
		.limit(1)
		.maybeSingle();

	let myTeamId: string | null = ledTeam?.id ?? null;
	let myTeamLeaderId: string | null = ledTeam?.leader_id ?? null;

	if (!myTeamId) {
		const { data: membership } = await supabase
			.from('team_members')
			.select('team_id, teams(leader_id)')
			.eq('user_id', user!.id)
			.eq('status', 'active')
			.limit(1)
			.maybeSingle();
		myTeamId = membership?.team_id ?? null;
		myTeamLeaderId = (membership?.teams as any)?.leader_id ?? null;
	}

	// ── All teams with member IDs (for Pick Teams grid) ──────────────────────
	const { data: teamsWithMembers } = await supabaseAdmin
		.from('teams')
		.select('id, name, leader_id, team_members(user_id, status)');

	// Collect all user IDs across all teams (leaders + active members)
	const allMemberIds = [
		...new Set([
			...(teamsWithMembers ?? []).map((t: any) => t.leader_id as string).filter(Boolean),
			...(teamsWithMembers ?? []).flatMap((t: any) =>
				(t.team_members ?? [])
					.filter((m: any) => m.status === 'active' && m.user_id)
					.map((m: any) => m.user_id as string)
			)
		])
	];

	// Fetch all availabilities in the grid window for all relevant users
	let memberAvails: { user_id: string; starts_at: string; ends_at: string }[] = [];
	if (allMemberIds.length > 0) {
		const { data } = await supabaseAdmin
			.from('availabilities')
			.select('user_id, starts_at, ends_at')
			.in('user_id', allMemberIds)
			.lt('starts_at', windowEnd)
			.gt('ends_at', windowStart);
		memberAvails = data ?? [];
	}

	// Build per-user slot sets
	const slotsByUser = new Map<string, Set<string>>();
	for (const avail of memberAvails) {
		if (!slotsByUser.has(avail.user_id)) slotsByUser.set(avail.user_id, new Set());
		for (const k of slotsFromWindow(avail.starts_at, avail.ends_at, viewerTz, validDates)) {
			slotsByUser.get(avail.user_id)!.add(k);
		}
	}

	// Per-team aggregate slot data (for Pick Teams tab) — only meaningful if viewer has a team
	const teamSlotData = myTeamId === null ? [] : (teamsWithMembers ?? []).filter((t: any) => t.id !== myTeamId).map((team: any) => {
		const memberIds: string[] = [
			team.leader_id as string,
			...(team.team_members ?? [])
				.filter((m: any) => m.status === 'active' && m.user_id && m.user_id !== team.leader_id)
				.map((m: any) => m.user_id as string)
		].filter(Boolean);
		const teamSlots = new Set<string>();
		for (const uid of memberIds) {
			const s = slotsByUser.get(uid);
			if (s) for (const k of s) teamSlots.add(k);
		}
		return { id: team.id as string, name: team.name as string, slots: Array.from(teamSlots) };
	});

	// Per-member slot data for viewer's own team (for time-first calendar)
	let myTeamMembers: { id: string; name: string; slots: string[] }[] = [];
	if (myTeamId) {
		const myTeamData = (teamsWithMembers ?? []).find((t: any) => t.id === myTeamId);
		const myMemberIds: string[] = myTeamData
			? [
					myTeamLeaderId as string,
					...(myTeamData.team_members ?? [])
						.filter(
							(m: any) => m.status === 'active' && m.user_id && m.user_id !== myTeamLeaderId
						)
						.map((m: any) => m.user_id as string)
				].filter(Boolean)
			: [];

		if (myMemberIds.length > 0) {
			const { data: memberProfiles } = await supabaseAdmin
				.from('profiles')
				.select('id, username')
				.in('id', myMemberIds);

			const profileMap = new Map(memberProfiles?.map((p) => [p.id, p.username as string]) ?? []);

			myTeamMembers = myMemberIds.map((uid) => ({
				id: uid,
				name: profileMap.get(uid) ?? uid,
				slots: Array.from(slotsByUser.get(uid) ?? new Set())
			}));
		}
	}

	return { teamSlotData, myTeamMembers, gridDays, viewerTz, weekOffset };
};

export const actions: Actions = {
	'time-first': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		const data = await request.formData();
		const slotStartIso = data.get('slot_start') as string;
		if (!slotStartIso) return fail(400, { timeFirstError: 'Please select a time slot.' });

		const slotStart = new Date(slotStartIso);
		if (isNaN(slotStart.getTime())) return fail(400, { timeFirstError: 'Invalid time.' });

		const horizon = new Date(slotStart.getTime() + 14 * 24 * 3_600_000).toISOString();
		const nowIso = new Date().toISOString();

		// Use admin client so RLS doesn't restrict cross-team availability reads
		const { data: teams } = await supabaseAdmin
			.from('teams')
			.select('id, name, team_members(user_id, status)');

		const { data: allWindows } = await supabaseAdmin
			.from('availabilities')
			.select('user_id, starts_at, ends_at')
			.gte('ends_at', nowIso)
			.lte('starts_at', horizon);

		const windowsByUser = new Map<string, { starts_at: string; ends_at: string }[]>();
		for (const w of allWindows ?? []) {
			const list = windowsByUser.get(w.user_id) ?? [];
			list.push({ starts_at: w.starts_at, ends_at: w.ends_at });
			windowsByUser.set(w.user_id, list);
		}

		const teamsWithWindows = (teams ?? []).map((team: any) => {
			const memberIds: string[] = (team.team_members ?? [])
				.filter((m: any) => m.status === 'active')
				.map((m: any) => m.user_id)
				.filter(Boolean);
			return {
				id: team.id,
				name: team.name,
				windows: memberIds.flatMap((uid) => windowsByUser.get(uid) ?? [])
			};
		});

		// Find viewer's own team to exclude it from results
		let viewerTeamId: string | null = null;
		if (user) {
			const { data: ledTeam } = await supabase
				.from('teams')
				.select('id')
				.eq('leader_id', user.id)
				.limit(1)
				.maybeSingle();
			viewerTeamId = ledTeam?.id ?? null;
			if (!viewerTeamId) {
				const { data: mem } = await supabase
					.from('team_members')
					.select('team_id')
					.eq('user_id', user.id)
					.eq('status', 'active')
					.limit(1)
					.maybeSingle();
				viewerTeamId = mem?.team_id ?? null;
			}
		}

		const availableTeams = findTeamsForSlot(teamsWithWindows, slotStart).filter(
			(t) => t.id !== viewerTeamId
		);

		// Find fillers available for this 3h window
		const slotEnd = new Date(slotStart.getTime() + 3 * 3_600_000);

		const { data: fillerProfiles } = await supabaseAdmin
			.from('profiles')
			.select('id, username, timezone')
			.eq('role', 'filler');

		let fillerResults: { id: string; username: string; timezone: string }[] = [];
		if (fillerProfiles && fillerProfiles.length > 0) {
			const fillerIds = fillerProfiles.map((f) => f.id);
			const { data: fillerWindows } = await supabaseAdmin
				.from('availabilities')
				.select('user_id, starts_at, ends_at')
				.in('user_id', fillerIds)
				.lte('starts_at', slotStart.toISOString())
				.gte('ends_at', slotEnd.toISOString());

			const availableFillerIds = new Set(fillerWindows?.map((w) => w.user_id) ?? []);
			fillerResults = fillerProfiles.filter(
				(f) => availableFillerIds.has(f.id) && f.id !== user?.id
			);
		}

		return { timeFirstResults: availableTeams, fillerResults, slotStart: slotStartIso };
	},

	'create-scrim': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const startsAt = data.get('starts_at') as string;
		const opponentTeamIds = data.getAll('team_id') as string[];

		if (!startsAt) return fail(400, { error: 'Missing start time.' });
		if (opponentTeamIds.length !== 5) return fail(400, { error: 'Exactly 5 opponent teams are required.' });

		// Resolve the organizer's own team and include it in the scrim
		const { data: ledTeam } = await supabase
			.from('teams')
			.select('id')
			.eq('leader_id', user.id)
			.limit(1)
			.maybeSingle();
		let myTeamId: string | null = ledTeam?.id ?? null;
		if (!myTeamId) {
			const { data: membership } = await supabase
				.from('team_members')
				.select('team_id')
				.eq('user_id', user.id)
				.eq('status', 'active')
				.limit(1)
				.maybeSingle();
			myTeamId = membership?.team_id ?? null;
		}
		if (!myTeamId) return fail(400, { error: 'You must be part of a team to create a scrim.' });

		const teamIds = [myTeamId, ...opponentTeamIds];

		const { data: scrim, error: scrimError } = await supabase
			.from('scrims')
			.insert({ organizer_id: user.id, starts_at: startsAt, status: 'proposed' })
			.select('id')
			.single();

		if (scrimError || !scrim)
			return fail(500, { error: scrimError?.message ?? 'Failed to create scrim.' });

		const { error: teamsError } = await supabase
			.from('scrim_teams')
			.insert(teamIds.map((id) => ({ scrim_id: scrim.id, team_id: id })));

		if (teamsError) return fail(500, { error: teamsError.message });

		return { scrimCreated: true };
	}
};
