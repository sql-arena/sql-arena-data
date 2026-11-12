import { TABLE_BUCKET_ARN, REPO_DIR, STATUS_DIR } from '$app/env/private';
import path from 'node:path';
import { parseTableBucketArn } from '#lib/tableBucket.ts';

export const SCALE_FACTORS = [1, 10, 1000];

function required(name: string, value: string | undefined): string {
	if (!value) throw new Error(`${name} is not set`);
	return value;
}

export function config() {
	const bucket = parseTableBucketArn(required('TABLE_BUCKET_ARN', TABLE_BUCKET_ARN));
	return {
		bucket,
		tableBucketArn: bucket.arn,
		region: bucket.region,
		repoDir: required('REPO_DIR', REPO_DIR),
		statusDir: required('STATUS_DIR', STATUS_DIR)
	};
}

export function namespace(sf: number): string {
	return `agenttelemetry_sf${sf}`;
}

export function statusFile(sf: number): string {
	return path.join(config().statusDir, `sf${sf}.jsonl`);
}

export function logFile(sf: number): string {
	return path.join(config().statusDir, `sf${sf}.log`);
}

export function parseScaleFactor(value: string | null): number {
	const sf = Number(value ?? 10);
	if (!SCALE_FACTORS.includes(sf))
		throw new Error(`Scale factor must be one of ${SCALE_FACTORS.join(', ')}`);
	return sf;
}
