import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { config } from './config.ts';
import { distinctValues, type ColumnDistinct } from './duckdb.ts';

export interface DistinctCounts {
	counted: string;
	milliseconds: number;
	columns: ColumnDistinct[];
}

const counting = new Map<string, Promise<DistinctCounts>>();

function cacheFile(ns: string, table: string): string {
	return path.join(config().statusDir, 'distinct', `${ns}.${table}.json`);
}

/** The counts cached by an earlier count; an unreadable cache is a miss. */
export async function cachedDistinctCounts(
	ns: string,
	table: string
): Promise<DistinctCounts | undefined> {
	try {
		return JSON.parse(await readFile(cacheFile(ns, table), 'utf8')) as DistinctCounts;
	} catch {
		return undefined;
	}
}

async function count(ns: string, table: string): Promise<DistinctCounts> {
	const started = performance.now();
	const counts = {
		counted: new Date().toISOString(),
		columns: await distinctValues(ns, table),
		milliseconds: Math.round(performance.now() - started)
	};
	const file = cacheFile(ns, table);
	try {
		await mkdir(path.dirname(file), { recursive: true });
		await writeFile(file, JSON.stringify(counts));
	} catch (e) {
		console.error(`Could not cache distinct counts in ${file}`, e);
	}
	return counts;
}

/** Counts a table once, however many pages ask while it runs, and caches the result. */
export function distinctCounts(ns: string, table: string): Promise<DistinctCounts> {
	const key = `${ns}.${table}`;
	let pending = counting.get(key);
	if (!pending) {
		pending = count(ns, table).finally(() => counting.delete(key));
		counting.set(key, pending);
	}
	return pending;
}

export async function forgetDistinctCounts(ns: string, table: string): Promise<void> {
	await rm(cacheFile(ns, table), { force: true });
}
