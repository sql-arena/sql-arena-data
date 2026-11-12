import { describe, expect, it } from 'vitest';
import { partitionPath, summarize } from './iceberg.ts';

const metadata = {
	'format-version': 2,
	'current-schema-id': 0,
	schemas: [
		{
			'schema-id': 0,
			fields: [
				{ id: 1, name: 'trace_id' },
				{ id: 4, name: 'session_id' },
				{ id: 16, name: 'start_time' }
			]
		}
	],
	'default-spec-id': 1,
	'partition-specs': [
		{ 'spec-id': 0, fields: [] },
		{ 'spec-id': 1, fields: [{ name: 'start_time_day', transform: 'day', 'source-id': 16 }] }
	],
	'default-sort-order-id': 1,
	'sort-orders': [
		{ 'order-id': 0, fields: [] },
		{
			'order-id': 1,
			fields: [
				{ transform: 'identity', 'source-id': 1, direction: 'asc', 'null-order': 'nulls-last' },
				{ transform: 'identity', 'source-id': 4, direction: 'desc', 'null-order': 'nulls-last' }
			]
		}
	],
	properties: { 'write.parquet.compression-codec': 'zstd' },
	'current-snapshot-id': 2,
	snapshots: [
		{
			'snapshot-id': 1,
			'timestamp-ms': Date.UTC(2026, 10, 11, 12, 34),
			'manifest-list': 's3://w/metadata/snap-1.avro',
			summary: { operation: 'append', 'added-data-files': '271', 'added-records': '636990' }
		},
		{
			'snapshot-id': 2,
			'timestamp-ms': Date.UTC(2026, 10, 11, 12, 35),
			'manifest-list': 's3://w/metadata/snap-2.avro',
			summary: {
				operation: 'append',
				'added-data-files': '95',
				'added-records': '355008',
				'agenttelemetry.chunk': '2025-09-29 to 2025-12-31',
				'total-data-files': '366',
				'total-files-size': '436479746',
				'total-records': '991998'
			}
		}
	]
};

describe('summarize', () => {
	it('names the default partitioning and sort order by column', () => {
		const s = summarize(JSON.stringify(metadata));
		expect(s.partitioning).toBe('day(start_time)');
		expect(s.sortOrder).toBe('trace_id, session_id desc');
		expect(s.properties).toEqual([['write.parquet.compression-codec', 'zstd']]);
	});

	it('takes the totals and manifest list of the current snapshot', () => {
		const s = summarize(JSON.stringify(metadata));
		expect([s.files, s.bytes, s.records]).toEqual([366, 436479746, 991998]);
		expect(s.manifestList).toBe('s3://w/metadata/snap-2.avro');
		expect(s.snapshots.map((x) => x.chunk)).toEqual([undefined, '2025-09-29 to 2025-12-31']);
		expect(s.snapshots[0].time).toBe('2026-11-11T12:34:00.000Z');
	});

	it('reads a table with no partitioning, sort order or snapshot', () => {
		const s = summarize(
			JSON.stringify({
				...metadata,
				'default-spec-id': 0,
				'default-sort-order-id': 0,
				'current-snapshot-id': undefined,
				snapshots: undefined
			})
		);
		expect([s.partitioning, s.sortOrder, s.files, s.manifestList]).toEqual([
			'none',
			'none',
			0,
			undefined
		]);
	});

	it('rejects metadata that refers to a missing column or spec', () => {
		expect(() => summarize(JSON.stringify({ ...metadata, 'default-spec-id': 7 }))).toThrow(
			/no partition spec 7/
		);
		const noColumn = structuredClone(metadata);
		noColumn.schemas[0].fields.pop();
		expect(() => summarize(JSON.stringify(noColumn))).toThrow(/no column 16/);
		expect(() => summarize('{"format-version": 2}')).toThrow(/Not an Iceberg/);
	});
});

describe('snapshot ids', () => {
	it('keeps 64-bit ids exact', () => {
		const json = JSON.stringify(metadata)
			.replace('"current-snapshot-id":2', '"current-snapshot-id": 5802105963362500804')
			.replace('"snapshot-id":2', '"snapshot-id":5802105963362500804');
		const s = summarize(json);
		expect(s.snapshots[1].id).toBe('5802105963362500804');
		expect(s.records).toBe(991998);
	});
});

describe('partitionPath', () => {
	it('writes the partition as key=value', () => {
		expect(partitionPath({ start_time_day: '2025-09-29' })).toBe('start_time_day=2025-09-29');
		expect(partitionPath(null)).toBe('');
	});
});
