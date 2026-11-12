import type { HandleServerError, ServerInit } from '@sveltejs/kit/hooks';
import { GENERATE_SF } from '$app/env/private';
import { parseScaleFactor } from '#lib/server/config.ts';
import { resumeGenerations, startGeneration } from '#lib/server/generation.ts';

/** Runs planned before serve their chunks again; GENERATE_SF starts that scale factor if it is not among them. */
export const init: ServerInit = async () => {
	const resumed = await resumeGenerations();
	if (GENERATE_SF && !resumed.includes(parseScaleFactor(GENERATE_SF)))
		startGeneration(parseScaleFactor(GENERATE_SF));
};

/** The app runs behind a private tunnel for its operator, so errors are shown in full. */
export const handleError: HandleServerError = ({ error }) => {
	console.error(error);
	return { message: error instanceof Error ? error.message : String(error) };
};
