<script lang="ts">
	import { invalidateAll } from '$app/navigation';

	let { seconds, active }: { seconds: number; active: boolean } = $props();

	$effect(() => {
		if (!active) return;
		const timer = setInterval(() => invalidateAll(), seconds * 1000);
		return () => clearInterval(timer);
	});
</script>
