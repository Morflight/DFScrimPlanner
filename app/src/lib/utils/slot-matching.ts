export interface AvailabilityWindow {
	starts_at: string;
	ends_at: string;
}

export interface MatchedSlot {
	starts_at: Date;
	ends_at: Date; // always starts_at + 3h
}

const SCRIM_DURATION_MS = 3 * 3_600_000;

/**
 * Given a list of availability windows for a team (any member), check if the team
 * has coverage for a given 3h slot [slotStart, slotStart+3h].
 * Coverage = at least one window fully contains the slot.
 */
export function teamCoversSlot(windows: AvailabilityWindow[], slotStart: Date): boolean {
	const slotEnd = new Date(slotStart.getTime() + SCRIM_DURATION_MS);
	return windows.some((w) => {
		const ws = new Date(w.starts_at);
		const we = new Date(w.ends_at);
		return ws <= slotStart && we >= slotEnd;
	});
}

/**
 * Time-first: given a specific slot start time and a list of teams with their windows,
 * return which teams are available for that slot.
 */
export function findTeamsForSlot(
	teams: { id: string; name: string; windows: AvailabilityWindow[] }[],
	slotStart: Date
): { id: string; name: string }[] {
	return teams.filter((t) => teamCoversSlot(t.windows, slotStart));
}

/**
 * Teams-first: given two teams' availability windows, find all 3h slots (on-the-hour)
 * within the next `lookaheadDays` days where both teams have coverage.
 */
export function findCommonSlots(
	teamAWindows: AvailabilityWindow[],
	teamBWindows: AvailabilityWindow[],
	lookaheadDays = 14
): MatchedSlot[] {
	const slots: MatchedSlot[] = [];
	const now = new Date();
	// Start from the next full hour
	const start = new Date(now);
	start.setMinutes(0, 0, 0);
	start.setHours(start.getHours() + 1);

	const end = new Date(start.getTime() + lookaheadDays * 24 * 3_600_000);

	for (let t = start.getTime(); t < end.getTime(); t += 3_600_000) {
		const slotStart = new Date(t);
		if (teamCoversSlot(teamAWindows, slotStart) && teamCoversSlot(teamBWindows, slotStart)) {
			slots.push({ starts_at: slotStart, ends_at: new Date(t + SCRIM_DURATION_MS) });
		}
	}

	return slots;
}
