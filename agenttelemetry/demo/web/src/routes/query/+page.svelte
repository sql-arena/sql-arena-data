<script lang="ts">
	import Panel from '#lib/components/Panel.svelte';
	import Form from '#lib/components/Form.svelte';
	import FormRow from '#lib/components/FormRow.svelte';
	import Select from '#lib/components/Select.svelte';
	import DateInput from '#lib/components/DateInput.svelte';
	import SqlEditor from '#lib/components/SqlEditor.svelte';
	import Button from '#lib/components/Button.svelte';
	import HiddenField from '#lib/components/HiddenField.svelte';
	import Alert from '#lib/components/Alert.svelte';
	import KeyValues from '#lib/components/KeyValues.svelte';
	import DataTable from '#lib/components/DataTable.svelte';
	import Paragraph from '#lib/components/Paragraph.svelte';
	import { count } from '#lib/format.ts';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	let running = $state(false);

	const sfOptions = $derived(
		data.scaleFactors.map((sf) => ({ value: String(sf), label: `SF${sf}` }))
	);
	const queryOptions = $derived(
		data.queries.map((q) => ({ value: q.name, label: `${q.name.toUpperCase()}: ${q.title}` }))
	);
	const result = $derived(form && 'result' in form ? form.result : undefined);
	const sql = $derived(form?.sql ?? data.sql);
</script>

<Panel title="Choose a query">
	<Form method="get" label="Choose a query">
		<FormRow>
			<Select
				label="Scale factor"
				name="sf"
				value={String(data.sf)}
				options={sfOptions}
				submitOnChange
			/>
			<Select label="Query" name="q" value={data.name} options={queryOptions} submitOnChange />
		</FormRow>
	</Form>
</Panel>

{#if data.needle}
	<Panel title="Needle">
		<Form method="get" label="Choose a needle">
			<HiddenField name="sf" value={String(data.sf)} />
			<HiddenField name="q" value={data.name} />
			<Paragraph muted>Look up {data.needle.description}.</Paragraph>
			<FormRow>
				<DateInput
					label="Day"
					name="day"
					value={data.needle.day}
					min={data.needle.firstDay}
					max={data.needle.lastDay}
					submitOnChange
				/>
				<Select
					label="Needle"
					name="slot"
					value={data.needle.slot}
					options={data.needle.options}
					submitOnChange
				/>
			</FormRow>
		</Form>
	</Panel>
{/if}

<Panel title="SQL">
	<Form
		action="?sf={data.sf}&q={data.name}&/run"
		label="Run the query"
		onsubmitting={(busy) => (running = busy)}
	>
		<SqlEditor label="Query on the S3 Tables catalog, through DuckDB" name="sql" value={sql} />
		<Button disabled={running}>{running ? 'Running…' : 'Run'}</Button>
	</Form>
</Panel>

{#if form?.error}
	<Alert kind="error">{form.error}</Alert>
{/if}

{#if result}
	<Panel title="Result">
		<KeyValues
			entries={[
				[
					'Rows',
					result.truncated ? `first ${count(result.rows.length)}` : count(result.rows.length)
				],
				['Time', `${(result.milliseconds / 1000).toFixed(2)} s`]
			]}
		/>
		<DataTable columns={result.columns} rows={result.rows} />
	</Panel>
{/if}
