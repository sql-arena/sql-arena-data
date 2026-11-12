<script lang="ts">
	import type { Snippet } from 'svelte';

	let { title, children }: { title: string; children: Snippet } = $props();
</script>

<nav class="site-nav" aria-label="Main">
	<span class="site-name">{title}</span>
	{@render children()}
</nav>
