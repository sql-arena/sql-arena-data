<script lang="ts">
	let {
		label,
		name,
		value,
		options,
		submitOnChange = false
	}: {
		label: string;
		name: string;
		value: string;
		options: { value: string; label: string }[];
		submitOnChange?: boolean;
	} = $props();
</script>

<label>
	{label}
	<select
		{name}
		{value}
		onchange={submitOnChange
			? (event) => (event.currentTarget as HTMLSelectElement).form?.requestSubmit()
			: undefined}
	>
		{#each options as option (option.value)}
			<option value={option.value}>{option.label}</option>
		{/each}
	</select>
</label>
