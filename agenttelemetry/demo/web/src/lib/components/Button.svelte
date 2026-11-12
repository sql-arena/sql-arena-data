<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		type = 'submit',
		variant = 'primary',
		disabled = false,
		name,
		value,
		children
	}: {
		type?: 'button' | 'submit';
		variant?: 'primary' | 'secondary';
		disabled?: boolean;
		name?: string;
		value?: string;
		children: Snippet;
	} = $props();
</script>

<button
	class={variant === 'secondary' ? 'button-secondary' : undefined}
	{type}
	{disabled}
	{name}
	{value}
>
	{@render children()}
</button>
