import { describe, expect, it } from 'vitest';
import {
	LEASE_MS,
	MAX_ATTEMPTS,
	MAX_STAGED,
	WorkQueue,
	type Committed,
	type Failure,
	type LedgerRecord,
	type Plan,
	type Staged
} from './workQueue.ts';

const plan: Plan = {
	sf: 10,
	namespace: 'agenttelemetry_sf10',
	table_bucket: 'arn:aws:s3tables:us-east-1:1:bucket/b',
	days: 2,
	sessions: 30,
	sessions_per_chunk: 10,
	tables: ['spans', 'traces'],
	locations: { spans: 's3://b/spans', traces: 's3://b/traces' },
	chunks: [
		{ id: '2025-01-01/0', day: 0, first: 0, last: 10 },
		{ id: '2025-01-01/10', day: 0, first: 10, last: 15 },
		{ id: '2025-01-02/0', day: 1, first: 0, last: 15 }
	]
};

const TIME = '2026-11-11T00:00:00Z';

function queue(ledger: LedgerRecord[] = [], chunks = plan.chunks): WorkQueue {
	let n = 0;
	return new WorkQueue({ ...plan, chunks }, ledger, () => `id${n++}`);
}

function file(table: string, chunk: string, rows: number) {
	return { path: `s3://b/${table}/data/day=0/${chunk}`, size: 100, rows, partition: [0] };
}

function staged(chunk: string, rows = 10): Staged {
	return {
		event: 'staged',
		time: TIME,
		chunk,
		worker: 'w',
		files: { spans: [file('spans', chunk, rows)], traces: [file('traces', chunk, rows / 10)] },
		generate_seconds: 2,
		write_seconds: 1
	};
}

function committed(table: string, chunks: string[], rows: number): Committed {
	return { event: 'committed', time: TIME, table, chunks, rows, snapshot: '1', seconds: 3 };
}

function failure(chunk: string): Failure {
	return { event: 'failed', time: TIME, chunk, worker: 'w', error: 'x' };
}

describe('WorkQueue leases', () => {
	it('hands out each chunk once, in plan order, with where to write it', () => {
		const q = queue();
		const first = q.lease('a', 0);
		expect(first).toMatchObject({
			chunk: { id: '2025-01-01/0' },
			locations: plan.locations,
			sf: 10
		});
		expect(q.lease('b', 0)?.chunk.id).toBe('2025-01-01/10');
		expect(q.lease('c', 0)?.chunk.id).toBe('2025-01-02/0');
		expect(q.lease('d', 0)).toBeUndefined();
	});

	it('hands the next chunk to whichever worker asks, however many there are', () => {
		const q = queue();
		expect(q.lease('a', 0)?.chunk.id).toBe('2025-01-01/0');
		expect(q.lease('a', 0)?.chunk.id).toBe('2025-01-01/10');
		expect(q.lease('new', 0)?.chunk.id).toBe('2025-01-02/0');
	});

	it('skips chunks the ledger has staged', () => {
		const q = queue([staged('2025-01-01/0'), staged('2025-01-01/10')]);
		expect(q.lease('a', 0)?.chunk.id).toBe('2025-01-02/0');
		expect(q.status(0)).toMatchObject({ staged: 2, committed: 0 });
	});

	it('gives a chunk out again when its lease runs out, and refuses the old lease', () => {
		const q = queue();
		const first = q.lease('a', 0)!;
		q.lease('b', 0);
		q.lease('c', 0);
		expect(q.lease('d', LEASE_MS - 1)).toBeUndefined();
		const again = q.lease('d', LEASE_MS)!;
		expect(again.chunk.id).toBe(first.chunk.id);
		expect(q.stage(first.lease, staged(first.chunk.id))).toBe(false);
		expect(q.stage(again.lease, staged(again.chunk.id))).toBe(true);
	});

	it('refuses a staged chunk that lacks a table', () => {
		const q = queue();
		const task = q.lease('a', 0)!;
		const partial = staged(task.chunk.id);
		delete partial.files.traces;
		expect(() => q.stage(task.lease, partial)).toThrow(/traces/);
	});

	it("refuses files outside their table's data", () => {
		const q = queue();
		const task = q.lease('a', 0)!;
		const elsewhere = staged(task.chunk.id);
		elsewhere.files.spans[0].path = 's3://b/traces/data/x.parquet';
		expect(() => q.stage(task.lease, elsewhere)).toThrow(/not in the storage of spans/);
		const metadata = staged(task.chunk.id);
		metadata.files.traces[0].path = 's3://b/traces/metadata/x.avro';
		expect(() => q.stage(task.lease, metadata)).toThrow(/not in the storage of traces/);
	});

	it('hands out nothing while MAX_STAGED chunks wait to be committed', () => {
		const chunks = Array.from({ length: MAX_STAGED + 1 }, (_, i) => ({
			id: `c${i}`,
			day: 0,
			first: i,
			last: i + 1
		}));
		const q = queue(
			chunks.slice(0, MAX_STAGED).map((c) => staged(c.id)),
			chunks
		);
		expect(q.lease('a', 0)).toBeUndefined();
		q.commitDone(committed('spans', ['c0'], 10), 0);
		expect(q.lease('a', 0)).toBeUndefined();
		q.commitDone(committed('traces', ['c0'], 1), 0);
		expect(q.lease('a', 0)?.chunk.id).toBe(`c${MAX_STAGED}`);
	});

	it('requeues a failed chunk until it failed MAX_ATTEMPTS times', () => {
		const q = queue(Array.from({ length: MAX_ATTEMPTS - 2 }, () => failure('2025-01-01/0')));
		const first = q.lease('a', 0)!;
		expect(q.fail(first.lease, failure(first.chunk.id))).toBe(true);
		expect(q.fail(first.lease, failure(first.chunk.id))).toBe(false);
		q.lease('b', 0);
		q.lease('c', 0);
		const again = q.lease('d', 0)!;
		expect(again.chunk.id).toBe(first.chunk.id);
		q.fail(again.lease, failure(again.chunk.id));
		expect(q.status(0).failed).toBe(1);
		expect(q.lease('e', 0)).toBeUndefined();
	});
});

describe('WorkQueue commits', () => {
	it('batches the files of staged chunks of a table in staging order, up to maxChunks', () => {
		const q = queue([
			staged('2025-01-01/0', 10),
			staged('2025-01-01/10', 20),
			staged('2025-01-02/0', 30)
		]);
		expect(q.batch('spans', 2)).toEqual({
			table: 'spans',
			chunks: ['2025-01-01/0', '2025-01-01/10'],
			files: [file('spans', '2025-01-01/0', 10), file('spans', '2025-01-01/10', 20)],
			rows: 30
		});
		expect(q.batch('spans', 2)).toBeUndefined();
		expect(q.batch('traces', 1)?.chunks).toEqual(['2025-01-01/0']);
	});

	it('commits the next batch after one is done, and offers a failed batch again', () => {
		const q = queue([staged('2025-01-01/0'), staged('2025-01-01/10')]);
		const first = q.batch('spans', 1)!;
		q.commitDone(committed('spans', first.chunks, 10), 0);
		const second = q.batch('spans', 1)!;
		expect(second.chunks).toEqual(['2025-01-01/10']);
		q.commitFailed({
			event: 'commit failed',
			time: TIME,
			table: 'spans',
			chunks: second.chunks,
			error: 'x'
		});
		expect(q.batch('spans', 1)?.chunks).toEqual(['2025-01-01/10']);
		expect(q.status(0).failures).toHaveLength(1);
	});

	it('counts a chunk committed when every table has it, and measures the rate', () => {
		const q = queue([staged('2025-01-01/0')]);
		q.commitDone(committed('spans', ['2025-01-01/0'], 10), 0);
		expect(q.status(0)).toMatchObject({ committed: 0, staged: 1 });
		q.commitDone(committed('traces', ['2025-01-01/0'], 1), 60_000);
		const status = q.status(60_000);
		expect(status).toMatchObject({ committed: 1, staged: 0, rows: { spans: 10, traces: 1 } });
		expect(status.chunksPerMinute).toBe(0.1);
		expect(status.remainingMinutes).toBe(20);
		expect(status.commits).toEqual([
			{ table: 'spans', commits: 1, averageChunks: 1, averageSeconds: 3 },
			{ table: 'traces', commits: 1, averageChunks: 1, averageSeconds: 3 }
		]);
	});

	it('picks up from the ledger: committed chunks are not offered again', () => {
		const q = queue([
			staged('2025-01-01/0'),
			staged('2025-01-01/10'),
			committed('spans', ['2025-01-01/0', '2025-01-01/10'], 20),
			committed('traces', ['2025-01-01/0'], 1)
		]);
		expect(q.batch('spans', 10)).toBeUndefined();
		expect(q.batch('traces', 10)?.chunks).toEqual(['2025-01-01/10']);
		expect(q.status(0)).toMatchObject({ committed: 1, staged: 1 });
	});

	it('is finished when every chunk is committed or failed for good', () => {
		const ledger: LedgerRecord[] = [staged('2025-01-01/0'), staged('2025-01-01/10')];
		for (const table of plan.tables)
			ledger.push(committed(table, ['2025-01-01/0', '2025-01-01/10'], 2));
		for (let i = 0; i < MAX_ATTEMPTS; i++) ledger.push(failure('2025-01-02/0'));
		const q = queue(ledger);
		expect(q.finished).toBe(true);
		expect(q.lease('a', 0)).toBeUndefined();
	});
});
