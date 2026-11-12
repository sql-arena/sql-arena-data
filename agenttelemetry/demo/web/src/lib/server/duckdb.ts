import {
	DuckDBInstance,
	BIGINT,
	INTEGER,
	VARCHAR,
	type DuckDBConnection,
	type Json
} from '@duckdb/node-api';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import attachSql from './sql/attach.sql?raw';
import sessionSql from './sql/session.sql?raw';
import needlesSql from './sql/needles.sql?raw';
import metadataSql from './sql/metadata.sql?raw';
import manifestsSql from './sql/manifests.sql?raw';
import dataFilesSql from './sql/data-files.sql?raw';
import describeSql from './sql/describe.sql?raw';
import distinctSql from './sql/distinct.sql?raw';
import { config } from './config.ts';
import { partitionPath, summarize, type IcebergSummary } from '#lib/iceberg.ts';

let instance: Promise<DuckDBInstance> | undefined;

/** ATTACH takes no bound parameters, so the ARN, checked against its pattern by config(), is put into the text. */
async function open(): Promise<DuckDBInstance> {
	const { tableBucketArn, region, repoDir } = config();
	const db = await DuckDBInstance.create(':memory:');
	const connection = await db.connect();
	try {
		await connection.run(
			attachSql.replaceAll('%%TABLE_BUCKET_ARN%%', tableBucketArn).replaceAll('%%REGION%%', region)
		);
		await connection.run(
			await readFile(path.join(repoDir, 'agenttelemetry/sql/needles.sql'), 'utf8')
		);
	} finally {
		connection.closeSync();
	}
	return db;
}

async function database(): Promise<DuckDBInstance> {
	instance ??= open().catch((e: unknown) => {
		instance = undefined;
		throw e;
	});
	return instance;
}

const MACROS = 'memory.main';

/** Names resolve in the namespace first, so its tables need no catalog prefix, then in the needle macros. */
async function withConnection<T>(
	searchPath: string,
	work: (connection: DuckDBConnection) => Promise<T>
): Promise<T> {
	const connection = await (await database()).connect();
	try {
		await connection.run(sessionSql.replaceAll('%%SEARCH_PATH%%', searchPath));
		return await work(connection);
	} finally {
		connection.closeSync();
	}
}

const NAME = /^[a-z0-9_]+$/;

function namespacePath(ns: string): string {
	if (!NAME.test(ns)) throw new Error(`Unexpected namespace ${ns}`);
	return `s3tables.${ns},${MACROS}`;
}

export interface QueryResult {
	columns: string[];
	rows: Json[][];
	truncated: boolean;
	milliseconds: number;
}

/** Runs sql in namespace ns of the S3 Tables catalog, keeping the first maxRows rows; interrupted after timeoutMs. */
export function runQuery(
	ns: string,
	sql: string,
	maxRows: number,
	timeoutMs: number
): Promise<QueryResult> {
	return withConnection(namespacePath(ns), async (connection) => {
		const started = performance.now();
		const timer = setTimeout(() => connection.interrupt(), timeoutMs);
		try {
			const reader = await connection.runAndReadUntil(sql, maxRows);
			return {
				columns: reader.columnNames(),
				rows: reader.getRowsJson().slice(0, maxRows),
				truncated: !reader.done || reader.currentRowCount > maxRows,
				milliseconds: Math.round(performance.now() - started)
			};
		} finally {
			clearTimeout(timer);
		}
	});
}

/** The needles of a family on day d, by slot 0 to slots - 1. */
export function needleValues(family: string, day: number, slots: number): Promise<string[]> {
	return withConnection(MACROS, async (connection) => {
		const reader = await connection.runAndReadAll(
			needlesSql,
			{ family, day, slots },
			{ family: VARCHAR, day: INTEGER, slots: BIGINT }
		);
		return reader.getRowsJson().map((row) => String(row[0]));
	});
}

const S3_PATH = /^s3:\/\/[\w./=-]+$/;

/** Paths are put into the SQL text, so only plain S3 paths, as S3 Tables writes them, are accepted. */
function s3Path(path: string): string {
	if (!S3_PATH.test(path)) throw new Error(`Unexpected S3 path ${path}`);
	return path;
}

/** The table metadata file S3 Tables points to, summarized. */
export function icebergMetadata(metadataLocation: string): Promise<IcebergSummary> {
	return withConnection(MACROS, async (connection) => {
		const reader = await connection.runAndReadAll(
			metadataSql.replaceAll('%%METADATA%%', s3Path(metadataLocation))
		);
		return summarize(String(reader.getRowsJson()[0][0]));
	});
}

export interface DataFile {
	path: string;
	partition: string;
	records: number;
	bytes: number;
}

/** The live data files of a snapshot, from the manifests in its manifest list. */
export function dataFiles(manifestList: string): Promise<DataFile[]> {
	return withConnection(MACROS, async (connection) => {
		const manifests = await connection.runAndReadAll(
			manifestsSql.replaceAll('%%MANIFEST_LIST%%', s3Path(manifestList))
		);
		const files: DataFile[] = [];
		for (const [manifest] of manifests.getRowsJson()) {
			const reader = await connection.runAndReadAll(
				dataFilesSql.replaceAll('%%MANIFEST%%', s3Path(String(manifest)))
			);
			for (const row of reader.getRowObjectsJson())
				files.push({
					path: String(row.path),
					partition: partitionPath(row.partition as Record<string, unknown> | null),
					records: Number(row.records),
					bytes: Number(row.bytes)
				});
		}
		return files.sort((a, b) => a.path.localeCompare(b.path));
	});
}

export interface ColumnDistinct {
	column: string;
	type: string;
	distinct: number;
}

/** Approximate distinct values (HyperLogLog) of every column of a table, in one scan, in column order. */
export function distinctValues(ns: string, table: string): Promise<ColumnDistinct[]> {
	if (!NAME.test(table)) throw new Error(`Unexpected table ${table}`);
	return withConnection(namespacePath(ns), async (connection) => {
		const columns = await connection.runAndReadAll(describeSql.replaceAll('%%TABLE%%', table));
		const reader = await connection.runAndReadAll(distinctSql.replaceAll('%%TABLE%%', table));
		const counts = reader.getRowObjectsJson()[0];
		return columns.getRowObjectsJson().map((c) => ({
			column: String(c.column_name),
			type: String(c.column_type),
			distinct: Number(counts[String(c.column_name)])
		}));
	});
}
