<script lang="ts">
	// Page layout component for consistent page styling
	export let title: string = '';
	export let description: string = '';
	export let maxWidth: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '4xl' | '6xl' | '7xl' | 'full' = '7xl';
	export let bgColor: string = 'bg-amber-50';
	export let padding: string = 'px-4 py-8';
</script>

<svelte:head>
	{#if title}
		<title>{title}</title>
	{/if}
	{#if description}
		<meta name="description" content={description} />
	{/if}
</svelte:head>

<div class={bgColor}>
	<div class="mx-auto max-w-{maxWidth} {padding}">
		<slot />
	</div>
</div>
