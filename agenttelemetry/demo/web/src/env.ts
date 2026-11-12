import { defineEnvVars } from '@sveltejs/kit/env';

const optional = (value: string | undefined) => value || undefined;

/** Optional here because the build runs the app without them; src/lib/server/config.ts requires them on use. */
export const variables = defineEnvVars({
	TABLE_BUCKET_ARN: {
		description: 'The S3 table bucket holding namespaces agenttelemetry_sf<N>',
		schema: optional
	},
	REPO_DIR: {
		description: 'The sql-arena-data checkout with the generator and the query files',
		schema: optional
	},
	STATUS_DIR: {
		description: 'Where generator runs write their status and log files',
		schema: optional
	},
	GENERATE_SF: {
		description: 'A scale factor to generate when the server starts',
		schema: optional
	}
});
