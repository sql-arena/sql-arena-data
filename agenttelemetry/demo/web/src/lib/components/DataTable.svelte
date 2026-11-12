<script lang="ts">
	let {
		caption,
		columns,
		rows,
		numeric = [],
		links
	}: {
		caption?: string;
		columns: string[];
		rows: string[][];
		numeric?: number[];
		/** A link for the first cell of each row. */
		links?: string[];
	} = $props();
</script>

<div class="table-scroll">
	<table>
		{#if caption}<caption>{caption}</caption>{/if}
		<thead>
			<tr>
				{#each columns as column, i (i)}
					<th scope="col" class={numeric.includes(i) ? 'number' : undefined}>{column}</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each rows as row, r (r)}
				<tr>
					{#each row as cell, i (i)}
						<td class={numeric.includes(i) ? 'number' : undefined}>
							{#if i === 0 && links}
								<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the page passes resolved links -->
								<a href={links[r]}>{cell}</a>
							{:else}
								{cell}
							{/if}
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>
