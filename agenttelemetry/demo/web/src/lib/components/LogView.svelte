<script lang="ts">
	let { lines }: { lines: string[] } = $props();
</script>

<pre class="log">{lines.join('\n')}</pre>
