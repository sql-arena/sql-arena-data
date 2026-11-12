<script lang="ts">
	import Panel from '#lib/components/Panel.svelte';
	import Form from '#lib/components/Form.svelte';
	import FormRow from '#lib/components/FormRow.svelte';
	import Select from '#lib/components/Select.svelte';
	import Button from '#lib/components/Button.svelte';
	import Alert from '#lib/components/Alert.svelte';
	import KeyValues from '#lib/components/KeyValues.svelte';
	import DataTable from '#lib/components/DataTable.svelte';
	import Paragraph from '#lib/components/Paragraph.svelte';
	import { count } from '#lib/format.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	let recounting = $state(false);

	const sfOptions = $derived(
		data.scaleFactors.map((sf) => ({ value: String(sf), label: `SF${sf}` }))
	);
	const tableOptions = $derived(data.tables.map((t) => ({ value: t, label: t })));
</script>

<Panel title="Distinct values per column">
	<Form method="get" label="Choose a table">
		<FormRow>
			<Select
				label="Scale factor"
				name="sf"
				value={String(data.sf)}
				options={sfOptions}
				submitOnChange
			/>
			{#if data.table !== undefined}
				<Select
					label="Table"
					name="table"
					value={data.table}
					options={tableOptions}
					submitOnChange
				/>
			{/if}
		</FormRow>
	</Form>
	<Paragraph muted>
		DuckDB's approx_count_distinct (HyperLogLog) over every column, in one scan of the table. Each
		table is counted once and the counts are kept until you count it again.
	</Paragraph>
</Panel>

{#if data.counting === undefined}
	<Alert>No tables in {data.namespace} yet.</Alert>
{:else}
	{#await data.counting}
		<Alert>Counting {data.namespace}.{data.table}, which reads the whole table…</Alert>
	{:then counting}
		{#if 'error' in counting}
			<Alert kind="error">{counting.error}</Alert>
		{:else}
			<Panel title="{data.namespace}.{data.table}">
				<KeyValues
					entries={[
						['Counted', counting.counts.counted],
						['Took', `${(counting.counts.milliseconds / 1000).toFixed(1)} s`]
					]}
				/>
				<Form
					action="?sf={data.sf}&table={data.table}&/recount"
					label="Count again"
					onsubmitting={(busy) => (recounting = busy)}
				>
					<Button variant="secondary" disabled={recounting}>Count again</Button>
				</Form>
				<DataTable
					columns={['Column', 'Type', 'Distinct values (approximate)']}
					rows={counting.counts.columns.map((c) => [c.column, c.type, count(c.distinct)])}
					numeric={[2]}
				/>
			</Panel>
		{/if}
	{/await}
{/if}
