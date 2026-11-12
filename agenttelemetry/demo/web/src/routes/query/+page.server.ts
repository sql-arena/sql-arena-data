import { error, fail } from '@sveltejs/kit';
import { SCALE_FACTORS, namespace, parseScaleFactor } from '#lib/server/config.ts';
import { needleValues, runQuery } from '#lib/server/duckdb.ts';
import { listQueries, readQuery } from '#lib/server/queries.ts';
import {
	DAYS,
	NEEDLE_QUERIES,
	chooseSlot,
	dayNumber,
	isoDate,
	needleLabel,
	rewrite
} from '#lib/needles.ts';
import { cell } from '#lib/format.ts';
import type { Actions, PageServerLoad } from './$types';

const MAX_ROWS = 1000;
const TIMEOUT_MS = 30 * 60 * 1000;

export const load: PageServerLoad = async ({ url }) => {
	const sf = parseScaleFactor(url.searchParams.get('sf'));
	const queries = await listQueries(sf);
	const name = url.searchParams.get('q') ?? queries[0].name;
	if (!queries.some((q) => q.name === name)) error(404, `No query ${name} at SF${sf}`);
	const sql = await readQuery(sf, name);
	const needle = NEEDLE_QUERIES[name];
	const base = { scaleFactors: SCALE_FACTORS, sf, queries, name };
	if (!needle) return { ...base, sql, needle: undefined };
	const day = url.searchParams.get('day') || needle.defaultDay;
	let slot: number | undefined;
	try {
		slot = chooseSlot(needle, url.searchParams.get('slot'), day);
		dayNumber(day);
	} catch (e) {
		error(400, e instanceof Error ? e.message : String(e));
	}
	const values = await needleValues(needle.family, dayNumber(day), needle.slots);
	return {
		...base,
		sql: slot === undefined ? sql : rewrite(sql, needle, values[slot], dayNumber(day)),
		needle: {
			description: needle.description,
			day,
			slot: slot === undefined ? '' : String(slot),
			options: [
				...(day === needle.defaultDay
					? [{ value: '', label: `${needle.checkedIn}, in the checked-in query` }]
					: []),
				...values.map((value, i) => ({ value: String(i), label: needleLabel(needle, i, value) }))
			],
			firstDay: isoDate(0),
			lastDay: isoDate(DAYS - 1)
		}
	};
};

export const actions: Actions = {
	run: async ({ request, url }) => {
		const sql = String((await request.formData()).get('sql') ?? '');
		if (!sql.trim()) return fail(400, { sql, error: 'Nothing to run' });
		const sf = parseScaleFactor(url.searchParams.get('sf'));
		try {
			const result = await runQuery(namespace(sf), sql, MAX_ROWS, TIMEOUT_MS);
			return {
				sql,
				result: { ...result, rows: result.rows.map((row) => row.map(cell)) }
			};
		} catch (e) {
			return fail(400, { sql, error: e instanceof Error ? e.message : String(e) });
		}
	}
};
