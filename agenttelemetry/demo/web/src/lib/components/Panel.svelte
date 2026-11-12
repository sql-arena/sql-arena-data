<script lang="ts">
	import type { Snippet } from 'svelte';

	let { title, badge, children }: { title: string; badge?: Snippet; children: Snippet } = $props();
</script>

<section class="panel">
	<header class="panel-header">
		<h2>{title}</h2>
		{#if badge}{@render badge()}{/if}
	</header>
	{@render children()}
</section>
