<script lang="ts">
	import Panel from '#lib/components/Panel.svelte';
	import DataTable from '#lib/components/DataTable.svelte';
	import KeyValues from '#lib/components/KeyValues.svelte';
	import Paragraph from '#lib/components/Paragraph.svelte';
	import { bytes, count, maintenanceJob } from '#lib/format.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const setup = $derived<[string, string][]>([
		['Metadata file', data.location],
		['Format version', String(data.iceberg.formatVersion)],
		['Partitioning', data.iceberg.partitioning],
		['Sort order', data.iceberg.sortOrder],
		...data.iceberg.properties,
		['Compaction (S3 Tables)', data.compaction],
		...data.jobs.map((j): [string, string] => [`${j.job} (S3 Tables)`, maintenanceJob(j)])
	]);
	const snapshots = $derived(
		data.iceberg.snapshots.map((s) => [
			s.id,
			s.time,
			s.operation,
			s.chunk ?? '',
			count(s.addedFiles),
			count(s.addedRecords)
		])
	);
	const files = $derived(
		data.files.map((f) => [
			f.path.replace(/^s3:\/\/[^/]+\//, ''),
			f.partition,
			count(f.records),
			bytes(f.bytes)
		])
	);
</script>

<Panel title="{data.namespace}.{data.table}">
	<KeyValues entries={setup} />
</Panel>

<Panel title="Snapshots">
	<DataTable
		columns={['Snapshot', 'Committed', 'Operation', 'Chunk', 'Added files', 'Added records']}
		rows={snapshots}
		numeric={[4, 5]}
	/>
</Panel>

<Panel title="Data files">
	<Paragraph muted>
		{count(data.files.length)} files of the current snapshot, {bytes(data.iceberg.bytes)}, from its
		manifests. S3 Tables does not list the objects of a table bucket, so the manifests are the only
		index of its files.
	</Paragraph>
	<DataTable columns={['Path', 'Partition', 'Records', 'Size']} rows={files} numeric={[2, 3]} />
</Panel>
