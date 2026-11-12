<script lang="ts">
	import type { Snippet } from 'svelte';
	import { resolve } from '$app/paths';
	import type { PageRouteId } from '$app/types';

	type PlainRoute = Exclude<PageRouteId, `${string}[${string}`>;

	let { href, current, children }: { href: PlainRoute; current: boolean; children: Snippet } =
		$props();
</script>

<a class="nav-link" href={resolve(href)} aria-current={current ? 'page' : undefined}
	>{@render children()}</a
>
