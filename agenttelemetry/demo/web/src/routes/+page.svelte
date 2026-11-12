<script lang="ts">
	import Panel from '#lib/components/Panel.svelte';
	import Form from '#lib/components/Form.svelte';
	import FormRow from '#lib/components/FormRow.svelte';
	import Select from '#lib/components/Select.svelte';
	import Button from '#lib/components/Button.svelte';
	import Alert from '#lib/components/Alert.svelte';
	import StatusBadge from '#lib/components/StatusBadge.svelte';
	import Progress from '#lib/components/Progress.svelte';
	import KeyValues from '#lib/components/KeyValues.svelte';
	import DataTable from '#lib/components/DataTable.svelte';
	import LogView from '#lib/components/LogView.svelte';
	import Paragraph from '#lib/components/Paragraph.svelte';
	import AutoRefresh from '#lib/components/AutoRefresh.svelte';
	import { count } from '#lib/format.ts';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();

	const options = $derived(
		data.scaleFactors.map((sf) => ({ value: String(sf), label: `SF${sf}` }))
	);

	function seconds(value: number | undefined): string {
		return value === undefined ? '' : value.toFixed(1);
	}
</script>

<AutoRefresh seconds={10} active={data.active.length > 0} />

<Panel title="Generate into S3 Tables">
	<Paragraph muted>
		The plan step creates namespace agenttelemetry_sf&lt;N&gt; and its tables. This server then
		hands out chunks of up to a few thousand sessions of one day to whichever worker process asks.
		Workers write each chunk as parquet files into the tables' storage, and this server commits the
		files to each table in batches. A run resumes after the chunks in its ledger.
	</Paragraph>
	<Form action="?/start" label="Start generation">
		<FormRow>
			<Select label="Scale factor" name="sf" value="10" {options} />
			<Button>Start</Button>
		</FormRow>
	</Form>
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
</Panel>

{#each data.runs as run (run.sf)}
	<Panel title="SF{run.sf}">
		{#snippet badge()}<StatusBadge state={run.state} />{/snippet}
		{#if run.queue && run.plan}
			<Progress label="Chunks committed" value={run.queue.committed} max={run.queue.chunks} />
			<KeyValues
				entries={[
					['Sessions', count(run.plan.sessions)],
					['Sessions per chunk', count(run.plan.sessions_per_chunk)],
					['Chunks being generated', count(run.queue.leased)],
					['Chunks written, waiting for a commit', count(run.queue.staged)],
					['Chunks failed for good', count(run.queue.failed)],
					['Chunks per minute', run.queue.chunksPerMinute?.toFixed(1) ?? ''],
					['Minutes left', run.queue.remainingMinutes?.toString() ?? ''],
					['Seconds to generate a chunk', seconds(run.queue.averageSeconds?.generate)],
					['Seconds to write its files', seconds(run.queue.averageSeconds?.write)]
				]}
			/>
			<DataTable
				caption="Commits, of the latest 200"
				columns={['Table', 'Rows committed', 'Commits', 'Chunks per commit', 'Seconds per commit']}
				rows={run.queue.commits.map((c) => [
					c.table,
					count(run.queue?.rows[c.table] ?? 0),
					count(c.commits),
					c.averageChunks.toFixed(1),
					c.averageSeconds.toFixed(1)
				])}
				numeric={[1, 2, 3, 4]}
			/>
			{#each run.queue.failures as failure, i (i)}
				<Alert kind="error">
					{failure.time}
					{failure.event === 'failed'
						? `${failure.chunk} ${failure.worker}`
						: `commit of ${failure.chunks.length} chunks to ${failure.table}`}: {failure.error}
				</Alert>
			{/each}
		{/if}
		{#if run.error}<Alert kind="error">{run.error}</Alert>{/if}
		<LogView lines={run.log} />
	</Panel>
{:else}
	<Alert>Nothing generated yet.</Alert>
{/each}

<Panel title="Workers">
	<DataTable
		columns={['Worker', 'Last seen, seconds ago', 'Chunk']}
		rows={data.workers.map((w) => [
			w.worker,
			Math.round((data.now - w.lastSeen) / 1000).toString(),
			w.chunk ?? ''
		])}
		numeric={[1]}
	/>
</Panel>
