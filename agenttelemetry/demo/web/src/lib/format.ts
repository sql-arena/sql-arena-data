export function count(n: number | undefined): string {
	return n === undefined ? '' : n.toLocaleString('en-US');
}

export function bytes(n: number): string {
	if (n < 1e6) return `${(n / 1e3).toFixed(1)} kB`;
	if (n < 1e9) return `${(n / 1e6).toFixed(1)} MB`;
	return `${(n / 1e9).toFixed(2)} GB`;
}

export function cell(value: unknown): string {
	if (value === null || value === undefined) return 'NULL';
	if (typeof value === 'object') return JSON.stringify(value);
	return String(value);
}

export function maintenanceJob(job: {
	status: string;
	lastRun?: string;
	failure?: string;
}): string {
	return [job.status, job.lastRun, job.failure].filter(Boolean).join(' ');
}
