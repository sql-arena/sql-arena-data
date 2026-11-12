<script lang="ts">
	import '#lib/styles/app.css';
	import favicon from '#lib/assets/favicon.svg';
	import { page } from '$app/state';
	import SiteNav from '#lib/components/SiteNav.svelte';
	import NavLink from '#lib/components/NavLink.svelte';
	import TableBucket from '#lib/components/TableBucket.svelte';
	import type { LayoutProps } from './$types';

	let { data, children }: LayoutProps = $props();

	const links = [
		{ href: '/', label: 'Generation' },
		{ href: '/tables', label: 'Tables' },
		{ href: '/query', label: 'Query' },
		{ href: '/columns', label: 'Columns' }
	] as const;

	function current(href: string): boolean {
		const path = page.url.pathname;
		return path === href || (href !== '/' && path.startsWith(`${href}/`));
	}
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>Agent Telemetry on S3 Tables</title>
</svelte:head>

<SiteNav title="Agent Telemetry on S3 Tables">
	{#each links as link (link.href)}
		<NavLink href={link.href} current={current(link.href)}>{link.label}</NavLink>
	{/each}
	<TableBucket bucket={data.bucket} />
</SiteNav>

<main>
	{@render children()}
</main>
