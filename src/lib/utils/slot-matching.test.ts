import { describe, it, expect } from 'vitest';
import { teamCoversSlot, findTeamsForSlot, findCommonSlots } from './slot-matching';

const h = (iso: string) => new Date(iso);

describe('teamCoversSlot', () => {
	it('returns true when a window fully covers the 3h slot', () => {
		const windows = [{ starts_at: '2026-04-01T10:00:00Z', ends_at: '2026-04-01T14:00:00Z' }];
		expect(teamCoversSlot(windows, h('2026-04-01T10:00:00Z'))).toBe(true);
	});

	it('returns false when the window is too short', () => {
		const windows = [{ starts_at: '2026-04-01T10:00:00Z', ends_at: '2026-04-01T12:00:00Z' }];
		expect(teamCoversSlot(windows, h('2026-04-01T10:00:00Z'))).toBe(false);
	});

	it('returns false when the slot starts before the window', () => {
		const windows = [{ starts_at: '2026-04-01T11:00:00Z', ends_at: '2026-04-01T15:00:00Z' }];
		expect(teamCoversSlot(windows, h('2026-04-01T10:00:00Z'))).toBe(false);
	});

	it('returns false with no windows', () => {
		expect(teamCoversSlot([], h('2026-04-01T10:00:00Z'))).toBe(false);
	});
});

describe('findTeamsForSlot', () => {
	const teams = [
		{
			id: 'a',
			name: 'Alpha',
			windows: [{ starts_at: '2026-04-01T10:00:00Z', ends_at: '2026-04-01T14:00:00Z' }]
		},
		{
			id: 'b',
			name: 'Bravo',
			windows: [{ starts_at: '2026-04-01T08:00:00Z', ends_at: '2026-04-01T11:00:00Z' }]
		}
	];

	it('returns only teams that cover the slot', () => {
		const result = findTeamsForSlot(teams, h('2026-04-01T10:00:00Z'));
		expect(result.map((t) => t.id)).toEqual(['a']);
	});
});

describe('findCommonSlots', () => {
	it('returns slots where both teams are available', () => {
		const future = new Date(Date.now() + 2 * 3_600_000).toISOString();
		const farFuture = new Date(Date.now() + 10 * 3_600_000).toISOString();
		const windowA = [{ starts_at: future, ends_at: farFuture }];
		const windowB = [{ starts_at: future, ends_at: farFuture }];
		const slots = findCommonSlots(windowA, windowB, 1);
		expect(slots.length).toBeGreaterThan(0);
		expect(slots[0].ends_at.getTime() - slots[0].starts_at.getTime()).toBe(3 * 3_600_000);
	});

	it('returns empty when teams have no overlap', () => {
		const a = [{ starts_at: '2030-01-01T10:00:00Z', ends_at: '2030-01-01T14:00:00Z' }];
		const b = [{ starts_at: '2030-01-01T18:00:00Z', ends_at: '2030-01-01T22:00:00Z' }];
		expect(findCommonSlots(a, b, 1)).toHaveLength(0);
	});
});
