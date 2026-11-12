import { error } from '@sveltejs/kit';
import { dataFiles, icebergMetadata } from '#lib/server/duckdb.ts';
import { compaction, maintenanceJobs, metadataLocation } from '#lib/server/maintenance.ts';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params }) => {
	const { namespace, table } = params;
	if (!/^[a-z0-9_]+$/.test(namespace + table)) error(404, `No table ${namespace}.${table}`);
	const location = await metadataLocation(namespace, table);
	const iceberg = await icebergMetadata(location);
	return {
		namespace,
		table,
		location,
		iceberg,
		compaction: await compaction(namespace, table),
		jobs: await maintenanceJobs(namespace, table),
		files: iceberg.manifestList ? await dataFiles(iceberg.manifestList) : []
	};
};
