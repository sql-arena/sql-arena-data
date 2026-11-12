<script lang="ts">
	let { label, value, max }: { label: string; value: number; max: number } = $props();
</script>

<label>
	{label}: {value} of {max}
	<progress {value} max={Math.max(max, 1)}></progress>
</label>
