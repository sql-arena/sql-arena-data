export type Family = 'trace' | 'session' | 'code' | 'place';

export interface NeedleQuery {
	family: Family;
	/** The needle the checked-in query looks up, replaced by the chosen one. */
	checkedIn: string;
	/** Needles of a day; every scale factor has them. */
	slots: number;
	window: (day: Date) => [Date, Date];
	/** The day of the checked-in needle. */
	defaultDay: string;
	description: string;
}

const DAY_MS = 86_400_000;
export const FIRST_DAY = new Date(Date.UTC(2025, 0, 1));
export const DAYS = 365;

function addDays(day: Date, days: number): Date {
	return new Date(day.getTime() + days * DAY_MS);
}

export const NEEDLE_QUERIES: Record<string, NeedleQuery> = {
	q01: {
		family: 'trace',
		checkedIn: '921e2a502330c3c5a575a230009d95c1',
		slots: 40,
		window: (day) => [day, addDays(day, 1)],
		defaultDay: '2025-10-28',
		description: 'the first run of a session of the day'
	},
	q02: {
		family: 'session',
		checkedIn: '1ed248067075d77e9611bb48b01a9f8f',
		slots: 40,
		window: (day) => [addDays(day, -1), addDays(day, 2)],
		defaultDay: '2025-10-28',
		description: 'a session of the day'
	},
	q11: {
		family: 'code',
		checkedIn: 'ERR_LEDGER_SHARD_7731',
		slots: 4,
		window: (day) => [day, addDays(day, 7)],
		defaultDay: '2025-10-06',
		description: 'an error code of the day, searched in the week from the day'
	},
	q13: {
		family: 'place',
		checkedIn: 'Ærøskøbing',
		slots: 1,
		window: (day) => [
			new Date(Date.UTC(day.getUTCFullYear(), day.getUTCMonth(), 1)),
			new Date(Date.UTC(day.getUTCFullYear(), day.getUTCMonth() + 1, 1))
		],
		defaultDay: '2025-02-03',
		description: 'the place of the day, searched in its month'
	}
};

/**
 * The needle chosen by the slot and day parameters: undefined for the checked-in one, which is shown until a slot or
 * another day is chosen; a new day without a slot takes its first needle.
 */
export function chooseSlot(
	needle: NeedleQuery,
	slot: string | null,
	day: string
): number | undefined {
	if (!slot) return day === needle.defaultDay ? undefined : 0;
	const n = Number(slot);
	if (!Number.isInteger(n) || n < 0 || n >= needle.slots)
		throw new Error(`The needle must be 0 to ${needle.slots - 1}`);
	return n;
}

export function needleLabel(needle: NeedleQuery, slot: number, value: string): string {
	switch (needle.family) {
		case 'trace':
		case 'session':
			return `Session ${slot}: ${value}`;
		case 'code':
			return `Code ${slot}: ${value}`;
		case 'place':
			return value;
	}
}

export function dayNumber(isoDate: string): number {
	const day = Math.round((Date.parse(`${isoDate}T00:00:00Z`) - FIRST_DAY.getTime()) / DAY_MS);
	if (!(day >= 0 && day < DAYS)) throw new Error(`${isoDate} is not a day of 2025`);
	return day;
}

export function isoDate(day: number): string {
	return addDays(FIRST_DAY, day).toISOString().slice(0, 10);
}

function timestamp(at: Date): string {
	return `${at.toISOString().slice(0, 10)} ${at.toISOString().slice(11, 19)}+00`;
}

/** The query with its checked-in needle and the two TIMESTAMPTZ bounds of its window replaced. */
export function rewrite(sql: string, needle: NeedleQuery, value: string, day: number): string {
	const bounds = [...sql.matchAll(/TIMESTAMPTZ '([^']+)'/g)].map((m) => m[0]);
	if (bounds.length !== 2)
		throw new Error(`Expected two TIMESTAMPTZ bounds, found ${bounds.length}`);
	if (!sql.includes(needle.checkedIn))
		throw new Error(`The query does not contain ${needle.checkedIn}`);
	const [start, end] = needle.window(addDays(FIRST_DAY, day));
	return sql
		.replaceAll(needle.checkedIn, value)
		.replace(bounds[0], `TIMESTAMPTZ '${timestamp(start)}'`)
		.replace(bounds[1], `TIMESTAMPTZ '${timestamp(end)}'`);
}
