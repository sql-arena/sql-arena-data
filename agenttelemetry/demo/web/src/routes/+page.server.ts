import { fail } from '@sveltejs/kit';
import { SCALE_FACTORS, parseScaleFactor } from '#lib/server/config.ts';
import {
	activeScaleFactors,
	generationStatus,
	startGeneration,
	workerStatus
} from '#lib/server/generation.ts';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async () => ({
	scaleFactors: SCALE_FACTORS,
	active: activeScaleFactors(),
	runs: await generationStatus(),
	workers: workerStatus(),
	now: Date.now()
});

export const actions: Actions = {
	start: async ({ request }) => {
		const form = await request.formData();
		try {
			startGeneration(parseScaleFactor(String(form.get('sf'))));
		} catch (e) {
			return fail(400, { error: e instanceof Error ? e.message : String(e) });
		}
	}
};
