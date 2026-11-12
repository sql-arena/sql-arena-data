<script lang="ts">
	import { resolve } from '$app/paths';
	import Panel from '#lib/components/Panel.svelte';
	import DataTable from '#lib/components/DataTable.svelte';
	import Alert from '#lib/components/Alert.svelte';
	import Paragraph from '#lib/components/Paragraph.svelte';
	import { bytes, count, maintenanceJob } from '#lib/format.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const jobNames = $derived(
		[...new Set(data.tables.flatMap((t) => t.jobs.map((j) => j.job)))].sort()
	);
	const rows = $derived(
		data.tables.map((t) => [
			`${t.namespace}.${t.name}`,
			t.partitioning,
			t.sortOrder,
			t.compaction,
			count(t.records),
			count(t.files),
			bytes(t.bytes),
			t.files ? bytes(t.bytes / t.files) : '',
			...jobNames.map((name) => {
				const job = t.jobs.find((j) => j.job === name);
				return job ? maintenanceJob(job) : '';
			})
		])
	);
	const links = $derived(
		data.tables.map((t) =>
			resolve('/tables/[namespace]/[table]', { namespace: t.namespace, table: t.name })
		)
	);
</script>

<Panel title="Tables">
	<Paragraph muted>
		Partitioning, sort order, files and records come from each table's Iceberg metadata, as of its
		current snapshot. Compaction and the maintenance jobs come from S3 Tables. Open a table to see
		its data files.
	</Paragraph>
	{#if data.tables.length}
		<DataTable
			columns={[
				'Table',
				'Partitioning',
				'Sort order',
				'Compaction',
				'Records',
				'Data files',
				'Size',
				'Average file',
				...jobNames
			]}
			{rows}
			{links}
			numeric={[4, 5, 6, 7]}
		/>
	{:else}
		<Alert>No tables in the table bucket yet.</Alert>
	{/if}
</Panel>
