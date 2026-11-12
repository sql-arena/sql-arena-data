import { error } from '@sveltejs/kit';
import type { DataFile } from '#lib/workQueue.ts';

function isDataFile(value: unknown): value is DataFile {
	if (typeof value !== 'object' || value === null) return false;
	const f = value as Record<string, unknown>;
	return (
		typeof f.path === 'string' &&
		Number.isInteger(f.size) &&
		Number.isInteger(f.rows) &&
		Array.isArray(f.partition) &&
		f.partition.every(Number.isInteger)
	);
}

/** The JSON body of a worker's request, with typed access that answers 400 to anything missing or mistyped. */
export async function workBody(request: Request) {
	const body = (await request.json().catch(() => error(400, 'The body is not JSON'))) as Record<
		string,
		unknown
	>;
	return {
		string(name: string): string {
			const value = body[name];
			if (typeof value !== 'string' || !value) error(400, `${name} must be a string`);
			return value;
		},
		number(name: string): number {
			const value = body[name];
			if (typeof value !== 'number' || !Number.isFinite(value))
				error(400, `${name} must be a number`);
			return value;
		},
		/** Data files by table: {table: [{path, size, rows, partition}]}. */
		dataFiles(name: string): Record<string, DataFile[]> {
			const value = body[name];
			if (typeof value !== 'object' || value === null || Array.isArray(value))
				error(400, `${name} must be an object`);
			for (const [table, files] of Object.entries(value))
				if (!Array.isArray(files) || !files.every(isDataFile))
					error(400, `${name}.${table} must be a list of data files`);
			return value as Record<string, DataFile[]>;
		}
	};
}
