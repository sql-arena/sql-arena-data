<script lang="ts">
	let { name, value }: { name: string; value: string } = $props();
</script>

<input type="hidden" {name} {value} />
