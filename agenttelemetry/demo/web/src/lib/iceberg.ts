interface Field {
	id: number;
	name: string;
}

interface Snapshot {
	'snapshot-id': string;
	'timestamp-ms': number;
	'manifest-list': string;
	summary: Record<string, string>;
}

/** The parts of an Iceberg table metadata file the app reads. */
interface Metadata {
	'format-version': number;
	'current-schema-id': number;
	schemas: { 'schema-id': number; fields: Field[] }[];
	'default-spec-id': number;
	'partition-specs': {
		'spec-id': number;
		fields: { name: string; transform: string; 'source-id': number }[];
	}[];
	'default-sort-order-id': number;
	'sort-orders': {
		'order-id': number;
		fields: { transform: string; 'source-id': number; direction: string; 'null-order': string }[];
	}[];
	properties?: Record<string, string>;
	'current-snapshot-id'?: string;
	snapshots?: Snapshot[];
}

export interface SnapshotSummary {
	id: string;
	time: string;
	operation: string;
	addedFiles: number;
	addedRecords: number;
	chunk?: string;
}

export interface IcebergSummary {
	formatVersion: number;
	partitioning: string;
	sortOrder: string;
	properties: [string, string][];
	files: number;
	bytes: number;
	records: number;
	snapshots: SnapshotSummary[];
	/** The manifest list of the current snapshot; none before the first. */
	manifestList?: string;
}

/** Snapshot ids are 64-bit integers, which JSON.parse would round, so they are read as strings. */
function quoteSnapshotIds(json: string): string {
	return json.replace(/("(?:current-|parent-)?snapshot-id"\s*:\s*)(-?\d+)/g, '$1"$2"');
}

function byId<T>(items: T[], key: keyof T, id: number, what: string): T {
	const item = items.find((i) => i[key] === id);
	if (!item) throw new Error(`The metadata has no ${what} ${id}`);
	return item;
}

function transformed(transform: string, name: string): string {
	return transform === 'identity' ? name : `${transform}(${name})`;
}

/** Summarizes a table metadata file: its default partitioning and sort order by column name, and its snapshots. */
export function summarize(json: string): IcebergSummary {
	const m = JSON.parse(quoteSnapshotIds(json)) as Metadata;
	if (!m.schemas || !m['partition-specs'] || !m['sort-orders'])
		throw new Error('Not an Iceberg table metadata file');
	const schema = byId(m.schemas, 'schema-id', m['current-schema-id'], 'schema');
	const column = (id: number) => byId(schema.fields, 'id', id, 'column').name;
	const spec = byId(m['partition-specs'], 'spec-id', m['default-spec-id'], 'partition spec');
	const order = byId(m['sort-orders'], 'order-id', m['default-sort-order-id'], 'sort order');
	const snapshots = m.snapshots ?? [];
	const current = snapshots.find((s) => s['snapshot-id'] === m['current-snapshot-id']);
	const total = (key: string) => Number(current?.summary[key] ?? 0);
	return {
		formatVersion: m['format-version'],
		partitioning:
			spec.fields.map((f) => transformed(f.transform, column(f['source-id']))).join(', ') || 'none',
		sortOrder:
			order.fields
				.map(
					(f) =>
						transformed(f.transform, column(f['source-id'])) +
						(f.direction === 'desc' ? ' desc' : '')
				)
				.join(', ') || 'none',
		properties: Object.entries(m.properties ?? {}),
		files: total('total-data-files'),
		bytes: total('total-files-size'),
		records: total('total-records'),
		snapshots: snapshots.map((s) => ({
			id: s['snapshot-id'],
			time: new Date(s['timestamp-ms']).toISOString(),
			operation: s.summary.operation ?? '',
			addedFiles: Number(s.summary['added-data-files'] ?? 0),
			addedRecords: Number(s.summary['added-records'] ?? 0),
			chunk: s.summary['agenttelemetry.chunk']
		})),
		manifestList: current?.['manifest-list']
	};
}

/** A data file's partition as Hive-style key=value pairs. */
export function partitionPath(partition: Record<string, unknown> | null): string {
	return Object.entries(partition ?? {})
		.map(([key, value]) => `${key}=${String(value)}`)
		.join('/');
}
