import { workFailed } from '#lib/server/generation.ts';
import { workBody } from '#lib/server/workBody.ts';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {
	const body = await workBody(request);
	workFailed(body.number('sf'), body.string('lease'), {
		worker: body.string('worker'),
		chunk: body.string('chunk'),
		error: body.string('error')
	});
	return new Response(null, { status: 204 });
};
