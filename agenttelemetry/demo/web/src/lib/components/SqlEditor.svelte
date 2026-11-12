<script lang="ts">
	let { label, name, value }: { label: string; name: string; value: string } = $props();
</script>

<label>
	{label}
	<textarea class="sql" {name} spellcheck="false" {value}></textarea>
</label>
