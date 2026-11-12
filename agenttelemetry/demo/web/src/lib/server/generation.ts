import { error } from '@sveltejs/kit';
import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { appendFileSync, closeSync, existsSync, mkdirSync, openSync, readdirSync } from 'node:fs';
import { readFile, rename } from 'node:fs/promises';
import path from 'node:path';
import {
	WorkQueue,
	type Batch,
	type DataFile,
	type Failure,
	type LedgerRecord,
	type Plan,
	type QueueStatus,
	type Staged,
	type Task
} from '#lib/workQueue.ts';
import { config } from './config.ts';
import { appendFiles } from './committer.ts';

export interface RunStatus {
	sf: number;
	state: 'planning' | 'running' | 'done' | 'failed';
	error?: string;
	plan?: Pick<Plan, 'sessions' | 'sessions_per_chunk'>;
	queue?: QueueStatus;
	log: string[];
}

export interface WorkerStatus {
	worker: string;
	lastSeen: number;
	chunk?: string;
}

interface Run {
	sf: number;
	queue?: WorkQueue;
	planning: boolean;
	error?: string;
}

/** Chunks of a table in one commit; a commit costs about the same however many files it adds. */
const COMMIT_CHUNKS = 400;
const COMMIT_POLL_MS = 2_000;

const runs = new Map<number, Run>();
const workers = new Map<string, WorkerStatus>();

function runDir(sf: number): string {
	return path.join(config().statusDir, 'generation', `sf${sf}`);
}

const files = (sf: number) => ({
	plan: path.join(runDir(sf), 'plan.json'),
	log: path.join(runDir(sf), 'plan.log'),
	ledger: path.join(runDir(sf), 'ledger.jsonl')
});

async function readLedger(file: string): Promise<LedgerRecord[]> {
	if (!existsSync(file)) return [];
	return (await readFile(file, 'utf8'))
		.split('\n')
		.filter((line) => line.trim())
		.map((line) => JSON.parse(line) as LedgerRecord);
}

async function load(run: Run): Promise<void> {
	const { plan, ledger } = files(run.sf);
	run.queue = new WorkQueue(
		JSON.parse(await readFile(plan, 'utf8')) as Plan,
		await readLedger(ledger),
		randomUUID
	);
}

function append(sf: number, record: LedgerRecord): void {
	appendFileSync(files(sf).ledger, JSON.stringify(record) + '\n');
}

/**
 * Runs the plan step, which creates the tables and loads the dimensions, then serves the chunks to workers. A run
 * planned before keeps its chunks, so the ledger stays valid; a fresh run needs its directory and tables deleted.
 */
export function startGeneration(sf: number): void {
	const existing = runs.get(sf);
	if (existing?.planning || (existing?.queue && !existing.queue.finished))
		throw new Error(`SF${sf} is already being generated`);
	const run: Run = { sf, planning: true };
	runs.set(sf, run);
	const { repoDir } = config();
	const { plan, log } = files(sf);
	mkdirSync(runDir(sf), { recursive: true });
	const out = openSync(log, 'w');
	const child = spawn(
		'uv',
		[
			'run',
			'--no-sync',
			'python',
			'-m',
			'agenttelemetry.s3tables',
			'plan',
			'--sf',
			String(sf),
			'--out',
			`${plan}.new`
		],
		{ cwd: repoDir, stdio: ['ignore', out, out] }
	);
	closeSync(out);
	child.on('exit', (code) => {
		void (async () => {
			try {
				if (code !== 0) throw new Error(`The plan step failed with exit code ${code}`);
				if (!existsSync(plan)) await rename(`${plan}.new`, plan);
				await load(run);
			} catch (e) {
				run.error = e instanceof Error ? e.message : String(e);
			} finally {
				run.planning = false;
			}
		})();
	});
}

/** Serves again the runs planned before the server started that are not finished, and starts committing. */
export async function resumeGenerations(): Promise<number[]> {
	setInterval(commitStaged, COMMIT_POLL_MS);
	const root = path.join(config().statusDir, 'generation');
	if (!existsSync(root)) return [];
	const resumed: number[] = [];
	for (const dir of readdirSync(root)) {
		const sf = Number(/^sf(\d+)$/.exec(dir)?.[1]);
		if (!sf || !existsSync(files(sf).plan)) continue;
		const run: Run = { sf, planning: false };
		await load(run);
		runs.set(sf, run);
		if (!run.queue!.finished) resumed.push(sf);
	}
	return resumed;
}

/** Starts a commit of every table of every run that has staged chunks and none being committed. */
function commitStaged(): void {
	for (const run of runs.values()) {
		const queue = run.queue;
		if (!queue) continue;
		for (const table of queue.plan.tables) {
			const batch = queue.batch(table, COMMIT_CHUNKS);
			if (batch) void commit(run.sf, queue, batch);
		}
	}
}

/** Appends the batch's files to its table in one commit and records it; a failed batch waits for the next try. */
async function commit(sf: number, queue: WorkQueue, batch: Batch): Promise<void> {
	const started = Date.now();
	const time = () => new Date().toISOString();
	try {
		const snapshot = await appendFiles(queue.plan.namespace, batch.table, batch.files);
		const record = {
			event: 'committed' as const,
			time: time(),
			table: batch.table,
			chunks: batch.chunks,
			rows: batch.rows,
			snapshot,
			seconds: (Date.now() - started) / 1000
		};
		append(sf, record);
		queue.commitDone(record, Date.now());
	} catch (e) {
		const failure = {
			event: 'commit failed' as const,
			time: time(),
			table: batch.table,
			chunks: batch.chunks,
			error: e instanceof Error ? e.message : String(e)
		};
		append(sf, failure);
		queue.commitFailed(failure);
	}
}

function seen(worker: string, chunk?: string): void {
	workers.set(worker, { worker, lastSeen: Date.now(), chunk });
}

/** The next chunk of the earliest started run that has one. */
export function leaseWork(worker: string): Task | undefined {
	for (const run of runs.values()) {
		const task = run.queue?.lease(worker, Date.now());
		if (task) {
			seen(worker, task.chunk.id);
			return task;
		}
	}
	seen(worker);
	return undefined;
}

function queue(sf: number): WorkQueue {
	const q = runs.get(sf)?.queue;
	if (!q) error(409, `SF${sf} is not being generated`);
	return q;
}

/** Takes a chunk a worker wrote; false when its lease has ended, as another worker has the chunk. */
export function workStaged(
	sf: number,
	lease: string,
	staged: Omit<Staged, 'event' | 'time'> & { files: Record<string, DataFile[]> }
): boolean {
	seen(staged.worker);
	const record: Staged = { event: 'staged', time: new Date().toISOString(), ...staged };
	if (!queue(sf).stage(lease, record)) return false;
	append(sf, record);
	return true;
}

export function workFailed(
	sf: number,
	lease: string,
	failure: Omit<Failure, 'event' | 'time'>
): void {
	seen(failure.worker);
	const record: Failure = { event: 'failed', time: new Date().toISOString(), ...failure };
	if (queue(sf).fail(lease, record)) append(sf, record);
}

async function tail(file: string, lines: number): Promise<string[]> {
	if (!existsSync(file)) return [];
	return (await readFile(file, 'utf8')).trimEnd().split('\n').slice(-lines);
}

export async function generationStatus(): Promise<RunStatus[]> {
	const now = Date.now();
	return Promise.all(
		[...runs.values()].map(async (run) => {
			const log = await tail(files(run.sf).log, 40);
			if (run.planning) return { sf: run.sf, state: 'planning' as const, log };
			if (!run.queue) return { sf: run.sf, state: 'failed' as const, error: run.error, log };
			const queueStatus = run.queue.status(now);
			const { sessions, sessions_per_chunk } = run.queue.plan;
			const state = !run.queue.finished
				? ('running' as const)
				: queueStatus.failed
					? ('failed' as const)
					: ('done' as const);
			return {
				sf: run.sf,
				state,
				plan: { sessions, sessions_per_chunk },
				queue: queueStatus,
				log
			};
		})
	);
}

/** Workers heard from in the last 15 minutes; the others have stopped. */
export function workerStatus(): WorkerStatus[] {
	const since = Date.now() - 15 * 60_000;
	for (const [id, w] of workers) if (w.lastSeen < since) workers.delete(id);
	return [...workers.values()].sort((a, b) => a.worker.localeCompare(b.worker));
}

export function activeScaleFactors(): number[] {
	return [...runs.values()]
		.filter((r) => r.planning || (r.queue && !r.queue.finished))
		.map((r) => r.sf);
}
