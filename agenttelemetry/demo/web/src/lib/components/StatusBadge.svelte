<script lang="ts">
	let { state }: { state: string } = $props();
</script>

<span class="status status-{state.replaceAll(' ', '-')}">{state}</span>
