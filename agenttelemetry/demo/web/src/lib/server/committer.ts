import { spawn, type ChildProcessWithoutNullStreams } from 'node:child_process';
import { createInterface } from 'node:readline';
import type { DataFile } from '#lib/workQueue.ts';
import { config } from './config.ts';

interface Answer {
	id: number;
	snapshot?: string;
	error?: string;
}

interface Pending {
	resolve: (snapshot: string) => void;
	reject: (error: Error) => void;
}

let running: ChildProcessWithoutNullStreams | undefined;
const pending = new Map<number, Pending>();
let nextId = 0;

/** The Python commit step, started once and again if it exits; its log goes to the server's. */
function committer(): ChildProcessWithoutNullStreams {
	if (running) return running;
	const child = spawn(
		'uv',
		['run', '--no-sync', 'python', '-m', 'agenttelemetry.s3tables', 'commit'],
		{
			cwd: config().repoDir
		}
	);
	child.stderr.pipe(process.stderr);
	createInterface({ input: child.stdout }).on('line', (line) => {
		const answer = JSON.parse(line) as Answer;
		const waiting = pending.get(answer.id);
		pending.delete(answer.id);
		if (answer.error !== undefined) waiting?.reject(new Error(answer.error));
		else waiting?.resolve(answer.snapshot!);
	});
	child.on('exit', (code) => {
		running = undefined;
		for (const waiting of pending.values())
			waiting.reject(new Error(`The commit step exited with code ${code}`));
		pending.clear();
	});
	running = child;
	return child;
}

/** Appends files that are already in the table's storage to the table, in one commit; resolves to its snapshot id. */
export function appendFiles(namespace: string, table: string, files: DataFile[]): Promise<string> {
	const id = nextId++;
	return new Promise((resolve, reject) => {
		pending.set(id, { resolve, reject });
		committer().stdin.write(JSON.stringify({ id, namespace, table, files }) + '\n');
	});
}
