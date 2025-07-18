<!--
Navigation Component (Legacy)

This component is now deprecated in favor of the Header component.
It's kept for backward compatibility but should not be used in new code.
Use Header.svelte instead for full header functionality.
-->

<script lang="ts">
	import LoginButton from '$lib/components/LoginButton.svelte';
	import { isAuthenticated } from '$lib/auth/keycloak';
	import { page } from '$app/stores';

	export let currentPage = '';

	// Get current route for active link styling if currentPage is not provided
	$: activeRoute = currentPage || $page.url.pathname;

	function isActivePage(path: string): boolean {
		return activeRoute === path;
	}
</script>

<nav class="flex items-center space-x-6">
	<a
		href="/"
		class="font-medium transition-colors {isActivePage('/')
			? 'font-semibold text-amber-900'
			: 'text-amber-700 hover:text-amber-900'}"
	>
		Home
	</a>

	<a
		href="/shop"
		class="font-medium transition-colors {isActivePage('/shop')
			? 'font-semibold text-amber-900'
			: 'text-amber-700 hover:text-amber-900'}"
	>
		Shop
	</a>

	<a
		href="/api-example"
		class="font-medium transition-colors {isActivePage('/api-example')
			? 'font-semibold text-amber-900'
			: 'text-amber-700 hover:text-amber-900'}"
	>
		API Demo
	</a>

	{#if $isAuthenticated}
		<a
			href="/protected"
			class="font-medium transition-colors {isActivePage('/protected')
				? 'font-semibold text-amber-900'
				: 'text-amber-700 hover:text-amber-900'}"
		>
			Management
		</a>
	{/if}

	<div class="border-l border-amber-300 pl-6">
		<LoginButton />
	</div>
</nav>
