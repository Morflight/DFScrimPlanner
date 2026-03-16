import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import { slotsFromWindow, weekStart } from '$lib/utils/timezone';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { user } = await safeGetSession();

	// Check if user leads a team
	const { data: ledTeam } = await supabase
		.from('teams')
		.select('id, name, leader_id, created_at')
		.eq('leader_id', user!.id)
		.limit(1)
		.maybeSingle();

	// Check if user is a member of a team
	const { data: membership } = await supabase
		.from('team_members')
		.select('team_id, status, teams(id, name, leader_id)')
		.eq('user_id', user!.id)
		.eq('status', 'active')
		.limit(1)
		.maybeSingle();

	const team = ledTeam ?? (membership?.teams as any) ?? null;
	const isLeader = !!ledTeam;

	let members: any[] = [];
	let pendingInvites: any[] = [];

	if (team) {
		const { data: memberRows } = await supabase
			.from('team_members')
			.select('id, user_id, invite_email, status, invited_at, activated_at, profiles(username, timezone)')
			.eq('team_id', team.id);
		members = (memberRows ?? []).filter((m: any) => m.status === 'active');
		pendingInvites = (memberRows ?? []).filter((m: any) => m.status === 'invited');
	}

	// Fetch viewer's timezone
	const { data: profile } = await supabase
		.from('profiles')
		.select('timezone')
		.eq('id', user!.id)
		.single();
	const viewerTz = profile?.timezone ?? 'UTC';

	// Build grid days: 7 days starting from today in the viewer's timezone
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
	const start = new Date(`${ty}-${tm}-${td}T00:00:00Z`);

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
			sub: new Intl.DateTimeFormat('en-US', { timeZone: viewerTz, month: 'short', day: 'numeric' }).format(d)
		};
	});

	// All user IDs to include: team leader first, then active members
	const memberUserIds = members
		.filter((m: any) => m.user_id)
		.map((m: any) => m.user_id as string);
	const allUserIds = team
		? [team.leader_id, ...memberUserIds.filter((id) => id !== team.leader_id)]
		: memberUserIds;

	const memberSlots: { userId: string; username: string; slots: string[] }[] = [];

	if (allUserIds.length > 0) {
		const windowStart = start.toISOString();
		const windowEnd = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString();

		// Fetch profiles and availabilities for all users (admin client bypasses RLS)
		const [{ data: profileRows }, { data: allAvails }] = await Promise.all([
			supabaseAdmin.from('profiles').select('id, username').in('id', allUserIds),
			supabaseAdmin
				.from('availabilities')
				.select('user_id, starts_at, ends_at')
				.in('user_id', allUserIds)
				.lt('starts_at', windowEnd)
				.gt('ends_at', windowStart)
		]);

		const profileMap = new Map(profileRows?.map((p) => [p.id, p.username as string]) ?? []);

		const slotsByUser = new Map<string, Set<string>>();
		for (const uid of allUserIds) slotsByUser.set(uid, new Set());
		for (const avail of allAvails ?? []) {
			const slots = slotsFromWindow(avail.starts_at, avail.ends_at, viewerTz, validDates);
			const s = slotsByUser.get(avail.user_id);
			if (s) for (const k of slots) s.add(k);
		}

		for (const uid of allUserIds) {
			memberSlots.push({
				userId: uid,
				username: profileMap.get(uid) ?? uid,
				slots: Array.from(slotsByUser.get(uid)!)
			});
		}
	}

	return { team, isLeader, members, pendingInvites, memberSlots, gridDays };
};

export const actions: Actions = {
	'create-team': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const name = (data.get('name') as string)?.trim();
		if (!name || name.length < 2) return fail(400, { error: 'Team name must be at least 2 characters.' });

		// Check user doesn't already lead a team
		const { data: existingTeams } = await supabase
			.from('teams')
			.select('id')
			.eq('leader_id', user.id)
			.limit(1);
		if (existingTeams && existingTeams.length > 0) return fail(400, { error: 'You already lead a team.' });

		const { error } = await supabase.from('teams').insert({ name, leader_id: user.id });
		if (error) return fail(500, { error: error.message });

		// Update role to leader
		await supabase.from('profiles').update({ role: 'leader' }).eq('id', user.id);

		redirect(303, '/team');
	},

	'invite-member': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const email = (data.get('email') as string)?.trim().toLowerCase();
		if (!email) return fail(400, { inviteError: 'Email is required.' });

		// Must be leader or active member of a team
		const { data: ledTeam } = await supabase
			.from('teams')
			.select('id')
			.eq('leader_id', user.id)
			.maybeSingle();
		const { data: membership } = ledTeam
			? { data: null }
			: await supabase
					.from('team_members')
					.select('team_id')
					.eq('user_id', user.id)
					.eq('status', 'active')
					.maybeSingle();
		const teamId = ledTeam?.id ?? membership?.team_id;
		const team = teamId ? { id: teamId } : null;
		if (!team) return fail(403, { inviteError: 'You must be a team leader or member to invite.' });

		// Don't re-invite same email
		const { data: existing } = await supabase
			.from('team_members')
			.select('id')
			.eq('team_id', team.id)
			.eq('invite_email', email)
			.maybeSingle();
		if (existing) return fail(400, { inviteError: 'This email has already been invited.' });

		// Create the team_members row first
		const { error: memberError } = await supabase.from('team_members').insert({
			team_id: team.id,
			invite_email: email,
			invite_token: crypto.randomUUID(),
			status: 'invited'
		});
		if (memberError) return fail(500, { inviteError: memberError.message });

		// Send the invite via Supabase Auth
		const { error: inviteError } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
			redirectTo: `${process.env.PUBLIC_SITE_URL ?? 'https://dfscrimplanner.local.com'}/auth/callback`
		});
		if (inviteError) {
			// Clean up the team_members row if invite failed
			await supabase.from('team_members').delete().eq('team_id', team.id).eq('invite_email', email);
			return fail(500, { inviteError: inviteError.message });
		}

		return { inviteSuccess: true };
	},

	'remove-member': async ({ request, locals: { supabase, safeGetSession } }) => {
		const { user } = await safeGetSession();
		if (!user) return fail(401, { error: 'Not authenticated.' });

		const data = await request.formData();
		const memberId = data.get('member_id') as string;

		// Must be leader of this team
		const { data: team } = await supabase
			.from('teams')
			.select('id')
			.eq('leader_id', user.id)
			.maybeSingle();
		if (!team) return fail(403, { error: 'Only team leaders can remove members.' });

		const { error } = await supabase
			.from('team_members')
			.delete()
			.eq('id', memberId)
			.eq('team_id', team.id);
		if (error) return fail(500, { error: error.message });

		return {};
	}
};
