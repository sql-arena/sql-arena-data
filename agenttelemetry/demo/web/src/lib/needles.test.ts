import { describe, expect, it } from 'vitest';
import { NEEDLE_QUERIES, chooseSlot, dayNumber, isoDate, needleLabel, rewrite } from './needles.ts';

const q01 = `SELECT * FROM agenttelemetry_sf1.spans
WHERE trace_id = '921e2a502330c3c5a575a230009d95c1'
  AND start_time >= TIMESTAMPTZ '2025-10-28 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-10-29 00:00:00+00'`;

const q11 = `/* the runs that saw error code ERR_LEDGER_SHARD_7731 */
SELECT 1 FROM spans WHERE (input_text LIKE '%ERR_LEDGER_SHARD_7731%' OR output_text LIKE '%ERR_LEDGER_SHARD_7731%')
  AND start_time >= TIMESTAMPTZ '2025-10-06 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-10-13 00:00:00+00'`;

describe('rewrite', () => {
	it('puts the needle and its day into a trace lookup', () => {
		const sql = rewrite(q01, NEEDLE_QUERIES.q01, 'abc', dayNumber('2025-03-05'));
		expect(sql).toContain("trace_id = 'abc'");
		expect(sql).toContain(
			"TIMESTAMPTZ '2025-03-05 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-03-06 00:00:00+00'"
		);
	});

	it('gives the checked-in query back for the checked-in needle', () => {
		const day = dayNumber(NEEDLE_QUERIES.q01.defaultDay);
		expect(rewrite(q01, NEEDLE_QUERIES.q01, NEEDLE_QUERIES.q01.checkedIn, day)).toBe(q01);
		expect(
			rewrite(q11, NEEDLE_QUERIES.q11, NEEDLE_QUERIES.q11.checkedIn, dayNumber('2025-10-06'))
		).toBe(q11);
	});

	it('replaces every occurrence of the needle', () => {
		const sql = rewrite(q11, NEEDLE_QUERIES.q11, 'ERR_0123456789AB', dayNumber('2025-12-30'));
		expect(sql).not.toContain('7731');
		expect(sql.match(/ERR_0123456789AB/g)).toHaveLength(3);
		expect(sql).toContain("TIMESTAMPTZ '2026-01-06 00:00:00+00'");
	});

	it('takes the month of the day for a place', () => {
		const sql = rewrite(
			`WHERE input_text LIKE '%Ærøskøbing%' AND start_time >= TIMESTAMPTZ '2025-02-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-03-01 00:00:00+00'`,
			NEEDLE_QUERIES.q13,
			'Kølébing',
			dayNumber('2025-12-17')
		);
		expect(sql).toBe(
			`WHERE input_text LIKE '%Kølébing%' AND start_time >= TIMESTAMPTZ '2025-12-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'`
		);
	});

	it('rejects a query without the checked-in needle', () => {
		expect(() => rewrite(q01.replace('921e', 'ffff'), NEEDLE_QUERIES.q01, 'abc', 0)).toThrow(
			/does not contain/
		);
	});

	it('rejects a query without exactly two time bounds', () => {
		expect(() =>
			rewrite(q01.split('\n').slice(0, 2).join('\n'), NEEDLE_QUERIES.q01, 'abc', 0)
		).toThrow(/two TIMESTAMPTZ bounds, found 0/);
	});
});

describe('days', () => {
	it('numbers the days of 2025 from 0', () => {
		expect(dayNumber('2025-01-01')).toBe(0);
		expect(dayNumber('2025-12-31')).toBe(364);
		expect(isoDate(300)).toBe('2025-10-28');
	});

	it('rejects days outside 2025', () => {
		expect(() => dayNumber('2026-01-01')).toThrow();
		expect(() => dayNumber('2024-12-31')).toThrow();
		expect(() => dayNumber('nonsense')).toThrow();
	});
});

describe('chooseSlot', () => {
	const q02 = NEEDLE_QUERIES.q02;

	it('keeps the checked-in needle until a slot or another day is chosen', () => {
		expect(chooseSlot(q02, null, q02.defaultDay)).toBeUndefined();
		expect(chooseSlot(q02, '', q02.defaultDay)).toBeUndefined();
	});

	it('takes the first needle of another day', () => {
		expect(chooseSlot(q02, '', '2025-03-05')).toBe(0);
	});

	it('takes the chosen slot on any day', () => {
		expect(chooseSlot(q02, '39', q02.defaultDay)).toBe(39);
		expect(chooseSlot(NEEDLE_QUERIES.q11, '3', '2025-01-01')).toBe(3);
	});

	it('rejects a slot the day does not have', () => {
		expect(() => chooseSlot(q02, '40', q02.defaultDay)).toThrow(/0 to 39/);
		expect(() => chooseSlot(NEEDLE_QUERIES.q13, '1', '2025-01-01')).toThrow(/0 to 0/);
		expect(() => chooseSlot(q02, '-1', q02.defaultDay)).toThrow();
		expect(() => chooseSlot(q02, '1.5', q02.defaultDay)).toThrow();
		expect(() => chooseSlot(q02, 'x', q02.defaultDay)).toThrow();
	});
});

describe('needleLabel', () => {
	it('names the session or code and shows the value', () => {
		expect(needleLabel(NEEDLE_QUERIES.q01, 3, 'abc')).toBe('Session 3: abc');
		expect(needleLabel(NEEDLE_QUERIES.q11, 1, 'ERR_X')).toBe('Code 1: ERR_X');
		expect(needleLabel(NEEDLE_QUERIES.q13, 0, 'Kølébing')).toBe('Kølébing');
	});
});
