<script lang="ts">
	import { page } from '$app/state';
	import Panel from '#lib/components/Panel.svelte';
	import Alert from '#lib/components/Alert.svelte';
</script>

<Panel title="Error {page.status}">
	<Alert kind="error">{page.error?.message}</Alert>
</Panel>
