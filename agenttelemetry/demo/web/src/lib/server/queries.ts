import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { config, namespace } from './config.ts';

export interface QueryFile {
	name: string;
	title: string;
}

/** The queries of every scale factor, with the namespace as %%NAMESPACE%%. */
function queryDir(): string {
	return path.join(config().repoDir, 'agenttelemetry/queries');
}

async function queryText(sf: number, name: string): Promise<string> {
	const sql = await readFile(path.join(queryDir(), `${name}.sql`), 'utf8');
	return sql.replaceAll('%%NAMESPACE%%', namespace(sf));
}

/** The title is the query's leading comment without its "Agent Telemetry Qnn: " prefix. */
function title(sql: string): string {
	const comment = /^\/\*\s*(.*?)\s*\*\//.exec(sql)?.[1] ?? '';
	return comment.replace(/^Agent Telemetry Q\d+:\s*/, '');
}

export async function listQueries(sf: number): Promise<QueryFile[]> {
	const files = (await readdir(queryDir())).filter((f) => /^q\d+\.sql$/.test(f)).sort();
	return Promise.all(
		files.map(async (f) => ({
			name: f.replace('.sql', ''),
			title: title(await queryText(sf, f.replace('.sql', '')))
		}))
	);
}

export async function readQuery(sf: number, name: string): Promise<string> {
	if (!/^q\d+$/.test(name)) throw new Error(`No query ${name}`);
	return queryText(sf, name);
}
