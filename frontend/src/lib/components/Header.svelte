<script lang="ts">
	import LoginButton from '$lib/components/LoginButton.svelte';
	import { isAuthenticated } from '$lib/auth/keycloak';
	import { page } from '$app/stores';

	// Get current route for active link styling
	$: currentPath = $page.url.pathname;

	function isActivePage(path: string): boolean {
		return currentPath === path;
	}
</script>

<header class="border-b border-amber-200 bg-white shadow-sm">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="flex items-center justify-between py-6">
			<div class="flex items-center">
				<a href="/" class="flex items-center">
					<h1 class="text-3xl font-bold text-amber-900">🏪 Perry Store</h1>
					<span class="ml-3 rounded-full bg-amber-100 px-2 py-1 text-sm text-amber-600"
						>Premium Items</span
					>
				</a>
			</div>

			<!-- Desktop Navigation -->
			<nav class="hidden space-x-8 md:flex">
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

			<!-- Mobile menu button (placeholder for future implementation) -->
			<div class="md:hidden">
				<LoginButton />
			</div>
		</div>
	</div>
</header>
