import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { user } = await safeGetSession();

	// Fetch user's team membership
	const { data: membership } = await supabase
		.from('team_members')
		.select('team_id, status, teams(id, name, leader_id)')
		.eq('user_id', user!.id)
		.eq('status', 'active')
		.maybeSingle();

	// Fetch led team (if user is a leader)
	const { data: ledTeam } = await supabase
		.from('teams')
		.select('id, name')
		.eq('leader_id', user!.id)
		.maybeSingle();

	// Fetch upcoming confirmed scrims for the user's team
	const teamId = ledTeam?.id ?? (membership?.teams as any)?.id;
	let upcomingScrims: any[] = [];
	if (teamId) {
		const { data } = await supabase
			.from('scrim_teams')
			.select('scrim_id, scrims(id, starts_at, status, organizer_id)')
			.eq('team_id', teamId);
		upcomingScrims = (data ?? [])
			.map((r: any) => r.scrims)
			.filter((s: any) => s && s.status !== 'cancelled' && new Date(s.starts_at) > new Date())
			.sort((a: any, b: any) => new Date(a.starts_at).getTime() - new Date(b.starts_at).getTime())
			.slice(0, 5);
	}

	// Fetch pending invites for the leader
	let pendingInvites: any[] = [];
	if (ledTeam) {
		const { data } = await supabase
			.from('team_members')
			.select('id, invite_email, status, invited_at')
			.eq('team_id', ledTeam.id)
			.eq('status', 'invited');
		pendingInvites = data ?? [];
	}

	return {
		team: ledTeam ?? (membership?.teams as any) ?? null,
		isLeader: !!ledTeam,
		upcomingScrims,
		pendingInvites
	};
};
