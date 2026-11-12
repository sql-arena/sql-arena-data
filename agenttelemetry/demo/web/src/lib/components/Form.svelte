<script lang="ts">
	import type { Snippet } from 'svelte';
	import { enhance } from '$app/forms';

	let {
		method = 'post',
		action,
		label,
		onsubmitting,
		children
	}: {
		method?: 'get' | 'post';
		action?: string;
		label: string;
		onsubmitting?: (busy: boolean) => void;
		children: Snippet;
	} = $props();
</script>

{#if method === 'post'}
	<form
		method="post"
		{action}
		aria-label={label}
		use:enhance={() => {
			onsubmitting?.(true);
			return async ({ update }) => {
				await update({ reset: false });
				onsubmitting?.(false);
			};
		}}
	>
		{@render children()}
	</form>
{:else}
	<form method="get" {action} aria-label={label}>
		{@render children()}
	</form>
{/if}
