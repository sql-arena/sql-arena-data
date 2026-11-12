import { json } from '@sveltejs/kit';
import { leaseWork } from '#lib/server/generation.ts';
import { workBody } from '#lib/server/workBody.ts';
import type { RequestHandler } from './$types';

/** The next chunk for a worker, or 204 when there is none. */
export const POST: RequestHandler = async ({ request }) => {
	const task = leaseWork((await workBody(request)).string('worker'));
	return task ? json(task) : new Response(null, { status: 204 });
};
