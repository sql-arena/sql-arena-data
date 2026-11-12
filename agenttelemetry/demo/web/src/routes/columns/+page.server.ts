import { error } from '@sveltejs/kit';
import { SCALE_FACTORS, namespace, parseScaleFactor } from '#lib/server/config.ts';
import { listTables } from '#lib/server/maintenance.ts';
import {
	cachedDistinctCounts,
	distinctCounts,
	forgetDistinctCounts,
	type DistinctCounts
} from '#lib/server/distinct.ts';
import type { Actions, PageServerLoad } from './$types';

type Counting = { counts: DistinctCounts } | { error: string };

async function chosenTable(url: URL): Promise<{ ns: string; tables: string[]; table?: string }> {
	const ns = namespace(parseScaleFactor(url.searchParams.get('sf')));
	const tables = (await listTables()).filter((t) => t.namespace === ns).map((t) => t.name);
	const table = url.searchParams.get('table') ?? tables[0];
	if (table !== undefined && !tables.includes(table)) error(404, `No table ${ns}.${table}`);
	return { ns, tables, table };
}

export const load: PageServerLoad = async ({ url }) => {
	const { ns, tables, table } = await chosenTable(url);
	const base = {
		scaleFactors: SCALE_FACTORS,
		sf: parseScaleFactor(url.searchParams.get('sf')),
		namespace: ns,
		tables,
		table
	};
	if (table === undefined) return { ...base, counting: undefined };
	const cached = await cachedDistinctCounts(ns, table);
	const counting: Counting | Promise<Counting> = cached
		? { counts: cached }
		: distinctCounts(ns, table).then(
				(counts) => ({ counts }),
				(e: unknown) => ({ error: e instanceof Error ? e.message : String(e) })
			);
	return { ...base, counting };
};

export const actions: Actions = {
	recount: async ({ url }) => {
		const { ns, table } = await chosenTable(url);
		if (table !== undefined) await forgetDistinctCounts(ns, table);
	}
};
