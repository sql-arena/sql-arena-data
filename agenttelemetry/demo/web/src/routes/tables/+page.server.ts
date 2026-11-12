import { icebergMetadata } from '#lib/server/duckdb.ts';
import {
	compaction,
	listTables,
	maintenanceJobs,
	metadataLocation
} from '#lib/server/maintenance.ts';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async () => {
	const tables = await Promise.all(
		(await listTables()).map(async (t) => ({
			...t,
			iceberg: await icebergMetadata(await metadataLocation(t.namespace, t.name)),
			compaction: await compaction(t.namespace, t.name),
			jobs: await maintenanceJobs(t.namespace, t.name)
		}))
	);
	return {
		tables: tables.map(({ iceberg, ...t }) => ({
			...t,
			partitioning: iceberg.partitioning,
			sortOrder: iceberg.sortOrder,
			files: iceberg.files,
			bytes: iceberg.bytes,
			records: iceberg.records
		}))
	};
};
