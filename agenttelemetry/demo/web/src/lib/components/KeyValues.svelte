<script lang="ts">
	let { entries }: { entries: [string, string][] } = $props();
</script>

<dl class="key-values">
	{#each entries as [key, value] (key)}
		<dt>{key}</dt>
		<dd>{value}</dd>
	{/each}
</dl>
