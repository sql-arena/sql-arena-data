<script lang="ts">
	import type { Snippet } from 'svelte';

	let { muted = false, children }: { muted?: boolean; children: Snippet } = $props();
</script>

<p class={muted ? 'muted' : undefined}>{@render children()}</p>
