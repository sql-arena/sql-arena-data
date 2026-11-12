<script lang="ts">
	let {
		label,
		name,
		value,
		min,
		max,
		submitOnChange = false
	}: {
		label: string;
		name: string;
		value: string;
		min: string;
		max: string;
		submitOnChange?: boolean;
	} = $props();
</script>

<label>
	{label}
	<input
		type="date"
		{name}
		{value}
		{min}
		{max}
		required
		onchange={submitOnChange
			? (event) => (event.currentTarget as HTMLInputElement).form?.requestSubmit()
			: undefined}
	/>
</label>
