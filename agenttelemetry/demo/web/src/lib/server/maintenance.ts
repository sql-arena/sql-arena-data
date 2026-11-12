import {
	S3TablesClient,
	GetTableMaintenanceConfigurationCommand,
	GetTableMaintenanceJobStatusCommand,
	GetTableMetadataLocationCommand,
	ListTablesCommand
} from '@aws-sdk/client-s3tables';
import { config } from './config.ts';

export interface MaintenanceJob {
	job: string;
	status: string;
	lastRun?: string;
	failure?: string;
}

let client: S3TablesClient | undefined;

function s3tables(): S3TablesClient {
	client ??= new S3TablesClient({ region: config().region });
	return client;
}

export interface TableName {
	namespace: string;
	name: string;
}

/** Every table in the table bucket, by namespace and name. */
export async function listTables(): Promise<TableName[]> {
	const { tableBucketArn } = config();
	const tables: TableName[] = [];
	let continuationToken: string | undefined;
	do {
		const page = await s3tables().send(
			new ListTablesCommand({ tableBucketARN: tableBucketArn, continuationToken })
		);
		for (const t of page.tables ?? [])
			tables.push({ namespace: (t.namespace ?? []).join('.'), name: t.name ?? '' });
		continuationToken = page.continuationToken;
	} while (continuationToken);
	return tables.sort(
		(a, b) => a.namespace.localeCompare(b.namespace) || a.name.localeCompare(b.name)
	);
}

export async function metadataLocation(ns: string, table: string): Promise<string> {
	const { tableBucketArn } = config();
	const result = await s3tables().send(
		new GetTableMetadataLocationCommand({
			tableBucketARN: tableBucketArn,
			namespace: ns,
			name: table
		})
	);
	if (!result.metadataLocation) throw new Error(`${ns}.${table} has no metadata yet`);
	return result.metadataLocation;
}

export async function maintenanceJobs(ns: string, table: string): Promise<MaintenanceJob[]> {
	const { tableBucketArn } = config();
	const result = await s3tables().send(
		new GetTableMaintenanceJobStatusCommand({
			tableBucketARN: tableBucketArn,
			namespace: ns,
			name: table
		})
	);
	return Object.entries(result.status ?? {}).map(([job, s]) => ({
		job,
		status: s.status ?? 'unknown',
		lastRun: s.lastRunTimestamp?.toISOString(),
		failure: s.failureMessage
	}));
}

/** The table's compaction setting in S3 Tables, such as "z-order, 512 MB". */
export async function compaction(ns: string, table: string): Promise<string> {
	const { tableBucketArn } = config();
	const result = await s3tables().send(
		new GetTableMaintenanceConfigurationCommand({
			tableBucketARN: tableBucketArn,
			namespace: ns,
			name: table
		})
	);
	const value = result.configuration?.icebergCompaction;
	if (!value || value.status !== 'enabled') return 'disabled';
	const settings = value.settings?.icebergCompaction;
	return [
		settings?.strategy ?? 'auto',
		settings?.targetFileSizeMB && `${settings.targetFileSizeMB} MB`
	]
		.filter(Boolean)
		.join(', ');
}
