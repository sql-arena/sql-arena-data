import { error, json } from '@sveltejs/kit';
import { workStaged } from '#lib/server/generation.ts';
import { workBody } from '#lib/server/workBody.ts';
import type { RequestHandler } from './$types';

/** A worker wrote a chunk's tables into their storage; 409 when its lease ended and another worker has the chunk. */
export const POST: RequestHandler = async ({ request }) => {
	const body = await workBody(request);
	const taken = workStaged(body.number('sf'), body.string('lease'), {
		worker: body.string('worker'),
		chunk: body.string('chunk'),
		files: body.dataFiles('files'),
		generate_seconds: body.number('generate_seconds'),
		write_seconds: body.number('write_seconds')
	});
	if (!taken) error(409, 'The lease of this chunk has ended');
	return json({ staged: true });
};
