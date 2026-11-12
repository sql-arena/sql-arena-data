export interface TableBucket {
	arn: string;
	region: string;
	account: string;
	name: string;
	/** The bucket in the S3 console; the viewer must be signed in to its account. */
	consoleUrl: string;
}

export function parseTableBucketArn(arn: string): TableBucket {
	const match = /^arn:aws:s3tables:([a-z0-9-]+):(\d{12}):bucket\/([a-z0-9-]+)$/.exec(arn);
	if (!match) throw new Error(`Not a table bucket ARN: ${arn}`);
	const [, region, account, name] = match;
	return {
		arn,
		region,
		account,
		name,
		consoleUrl: `https://${region}.console.aws.amazon.com/s3/table-buckets/${region}/${name}?region=${region}`
	};
}
