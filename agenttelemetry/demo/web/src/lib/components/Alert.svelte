<script lang="ts">
	import type { Snippet } from 'svelte';

	let { kind = 'info', children }: { kind?: 'info' | 'error'; children: Snippet } = $props();
</script>

<p class="alert alert-{kind}" role={kind === 'error' ? 'alert' : 'status'}>{@render children()}</p>
