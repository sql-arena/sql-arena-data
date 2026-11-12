<script lang="ts">
	import type { TableBucket } from '#lib/tableBucket.ts';

	let { bucket }: { bucket: TableBucket } = $props();
</script>

<p class="site-bucket">
	Table bucket
	<a class="site-bucket-link" href={bucket.consoleUrl} target="_blank" rel="external noopener"
		>{bucket.name}</a
	>
	in <strong>{bucket.region}</strong>, account {bucket.account}
</p>
