/**
 * Format a UTC ISO string into a human-readable string in the given IANA timezone.
 */
export function formatInTz(iso: string, tz: string, opts?: Intl.DateTimeFormatOptions): string {
	return new Intl.DateTimeFormat('en-US', {
		timeZone: tz,
		...opts
	}).format(new Date(iso));
}

/**
 * Get the start of the current week (Monday) at midnight UTC for a given IANA timezone.
 */
export function weekStart(tz: string): Date {
	const now = new Date();
	// Get the day-of-week in the target timezone
	const dayName = new Intl.DateTimeFormat('en-US', { timeZone: tz, weekday: 'short' }).format(now);
	const days: Record<string, number> = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
	const dayIndex = days[dayName] ?? 0;
	// Monday-based offset
	const offset = (dayIndex === 0 ? -6 : 1 - dayIndex);
	const monday = new Date(now);
	monday.setDate(now.getDate() + offset);
	monday.setHours(0, 0, 0, 0);
	return monday;
}

/**
 * Build a UTC Date from a local date string (YYYY-MM-DD) and hour (0–23) in the given IANA timezone.
 */
export function localToUtc(dateStr: string, hour: number, tz: string): Date {
	// Parse as a local time in the target timezone
	const localIso = `${dateStr}T${String(hour).padStart(2, '0')}:00:00`;
	// Use Intl to determine the UTC offset for that moment in the tz
	const utcMs = Date.parse(localIso + 'Z');
	const sample = new Date(utcMs);
	const parts = new Intl.DateTimeFormat('en-US', {
		timeZone: tz,
		year: 'numeric',
		month: '2-digit',
		day: '2-digit',
		hour: '2-digit',
		minute: '2-digit',
		second: '2-digit',
		hour12: false
	}).formatToParts(sample);

	const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '00';
	const localUtcStr = `${get('year')}-${get('month')}-${get('day')}T${get('hour')}:${get('minute')}:${get('second')}`;
	const offset = utcMs - Date.parse(localUtcStr + 'Z');
	return new Date(Date.parse(`${dateStr}T${String(hour).padStart(2, '0')}:00:00Z`) + offset);
}

/**
 * Check if two time ranges overlap.
 */
export function overlaps(
	aStart: Date,
	aEnd: Date,
	bStart: Date,
	bEnd: Date
): boolean {
	return aStart < bEnd && bStart < aEnd;
}

/**
 * Return the number of hours in the intersection of two ranges.
 */
export function overlapHours(aStart: Date, aEnd: Date, bStart: Date, bEnd: Date): number {
	const start = new Date(Math.max(aStart.getTime(), bStart.getTime()));
	const end = new Date(Math.min(aEnd.getTime(), bEnd.getTime()));
	return Math.max(0, (end.getTime() - start.getTime()) / 3_600_000);
}

/**
 * Given a date string (YYYY-MM-DD), return the start of the week
 * aligned to the given start day ('monday' or 'sunday').
 */
export function alignToWeekStart(
	dateStr: string,
	startDay: 'monday' | 'sunday' = 'monday'
): string {
	const date = new Date(dateStr + 'T12:00:00Z');
	const dow = date.getUTCDay(); // 0=Sun, 1=Mon, ... 6=Sat
	const target = startDay === 'sunday' ? 0 : 1;
	let diff = dow - target;
	if (diff < 0) diff += 7;
	const aligned = new Date(date);
	aligned.setUTCDate(aligned.getUTCDate() - diff);
	return aligned.toISOString().slice(0, 10);
}

/**
 * Return the default week start day based on timezone.
 * America/* → 'sunday', everything else → 'monday'.
 */
export function defaultWeekStart(tz: string): 'monday' | 'sunday' {
	return tz.startsWith('America/') ? 'sunday' : 'monday';
}

/**
 * Given a UTC availability window, return all 30-min slot keys (in the given IANA timezone)
 * that fall within the window, filtered to the provided set of valid date strings (YYYY-MM-DD).
 * Slot key format: "YYYY-MM-DDTHH:MM"
 */
export function slotsFromWindow(
	startsAt: string,
	endsAt: string,
	tz: string,
	validDates: Set<string>
): string[] {
	const step = 30 * 60 * 1000;
	const startMs = new Date(startsAt).getTime();
	const endMs = new Date(endsAt).getTime();
	// Align start down to nearest 30-min UTC boundary
	const alignedStart = startMs - (startMs % step);
	const result: string[] = [];
	const fmt = new Intl.DateTimeFormat('en-US', {
		timeZone: tz,
		year: 'numeric',
		month: '2-digit',
		day: '2-digit',
		hour: '2-digit',
		minute: '2-digit',
		hour12: false
	});
	for (let ms = alignedStart; ms < endMs; ms += step) {
		const parts = fmt.formatToParts(new Date(ms));
		const y = parts.find((p) => p.type === 'year')?.value ?? '';
		const mo = parts.find((p) => p.type === 'month')?.value ?? '';
		const d = parts.find((p) => p.type === 'day')?.value ?? '';
		let h = parts.find((p) => p.type === 'hour')?.value ?? '00';
		const mi = parts.find((p) => p.type === 'minute')?.value ?? '00';
		if (h === '24') h = '00';
		const dateStr = `${y}-${mo}-${d}`;
		if (validDates.has(dateStr)) {
			result.push(`${dateStr}T${h}:${mi}`);
		}
	}
	return result;
}
