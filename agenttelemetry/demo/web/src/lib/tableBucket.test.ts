import { describe, expect, it } from 'vitest';
import { parseTableBucketArn } from './tableBucket.ts';

describe('parseTableBucketArn', () => {
	it('takes the region, account and name, and links to the console', () => {
		const bucket = parseTableBucketArn(
			'arn:aws:s3tables:us-east-1:578125593767:bucket/sql-arena-agenttelemetry'
		);
		expect(bucket).toMatchObject({
			region: 'us-east-1',
			account: '578125593767',
			name: 'sql-arena-agenttelemetry'
		});
		expect(bucket.consoleUrl).toBe(
			'https://us-east-1.console.aws.amazon.com/s3/table-buckets/us-east-1/sql-arena-agenttelemetry?region=us-east-1'
		);
	});

	it('rejects anything but a table bucket ARN', () => {
		expect(() => parseTableBucketArn('arn:aws:s3:::sql-arena')).toThrow(/Not a table bucket ARN/);
		expect(() =>
			parseTableBucketArn('arn:aws:s3tables:us-east-1:578125593767:bucket/x/table/y')
		).toThrow();
		expect(() => parseTableBucketArn('')).toThrow();
	});
});
