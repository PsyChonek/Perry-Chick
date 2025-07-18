<script lang="ts">
	import { onMount } from 'svelte';
	import { api } from '$lib';
	import type { ApiConfig, ConfigStatus } from '$lib/types';
	import PageLayout from '$lib/components/PageLayout.svelte';

	let apiStatus = 'Checking...';
	let backendInfo: ApiConfig | null = null;
	let configStatus: ConfigStatus | null = null;

	onMount(async () => {
		// Test health endpoint
		const healthResponse = await api.health();
		if (healthResponse.data) {
			apiStatus = `Connected ✅ (v${healthResponse.data.version})`;
		} else {
			apiStatus = `Backend Unavailable ❌ (${healthResponse.error})`;
		}

		// Get backend info
		const rootResponse = await api.root();
		if (rootResponse.data) {
			backendInfo = rootResponse.data;
		}

		// Get config status (development only)
		const configResponse = await api.config();
		if (configResponse.data) {
			configStatus = configResponse.data;
		}
	});
</script>

<PageLayout
	title="Perry Store - Premium Items & Quality Goods"
	description="Welcome to Perry Store - Your premier destination for quality items and excellent service"
	bgColor="bg-gradient-to-br from-amber-50 to-orange-100"
	padding="px-0 py-0"
	maxWidth="full"
>
	<!-- Hero Section -->
	<section class="relative px-4 py-20 sm:px-6 lg:px-8">
		<div class="mx-auto max-w-7xl text-center">
			<h1 class="mb-6 text-5xl font-bold text-amber-900 md:text-6xl">
				Welcome to Perry Store
			</h1>
			<p class="mx-auto mb-8 max-w-3xl text-xl text-amber-700 md:text-2xl">
				Discover our premium collection of quality items. From delicious snacks to everyday
				essentials, we deliver excellence with every order.
			</p>
			<div class="flex flex-col items-center justify-center gap-4 sm:flex-row">
				<a
					href="/shop"
					class="rounded-lg bg-amber-600 px-8 py-4 text-lg font-semibold text-white shadow-lg transition-colors hover:bg-amber-700"
				>
					Shop Now
				</a>
				<a
					href="/about"
					class="rounded-lg border-2 border-amber-600 px-8 py-4 text-lg font-semibold text-amber-600 transition-colors hover:bg-amber-50"
				>
					Learn More
				</a>
			</div>
		</div>
	</section>

	<!-- Features Section -->
	<section class="bg-white px-4 py-16 sm:px-6 lg:px-8">
		<div class="mx-auto max-w-7xl">
			<h3 class="mb-12 text-center text-3xl font-bold text-amber-900">
				Why Choose Perry Chick?
			</h3>
			<div class="grid gap-8 md:grid-cols-3">
				<div class="text-center">
					<div class="mb-4 text-4xl">🍿</div>
					<h4 class="mb-2 text-xl font-semibold text-amber-800">Premium Popcorn</h4>
					<p class="text-amber-600">
						Hand-crafted gourmet popcorn made with the finest kernels and unique flavor
						combinations.
					</p>
				</div>
				<div class="text-center">
					<div class="mb-4 text-4xl">🥓</div>
					<h4 class="mb-2 text-xl font-semibold text-amber-800">Artisanal bacon</h4>
					<p class="text-amber-600">
						Carefully cured and smoked bacon using traditional methods for exceptional
						taste and quality.
					</p>
				</div>
				<div class="text-center">
					<div class="mb-4 text-4xl">🚚</div>
					<h4 class="mb-2 text-xl font-semibold text-amber-800">Fresh Delivery</h4>
					<p class="text-amber-600">
						Fast, reliable shipping to ensure your order arrives fresh and ready to
						enjoy.
					</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Status Section -->
	<section class="bg-amber-50 px-4 py-8 sm:px-6 lg:px-8">
		<div class="mx-auto max-w-4xl">
			<h3 class="mb-6 text-center text-2xl font-bold text-amber-900">System Status</h3>
			<div class="grid gap-6 md:grid-cols-2">
				<div class="rounded-lg bg-white p-6 shadow-sm">
					<h4 class="mb-2 text-lg font-semibold text-amber-800">Backend API</h4>
					<p class="text-amber-600">{apiStatus}</p>
					{#if backendInfo}
						<div class="mt-2 text-sm text-amber-500">
							<p>Environment: {backendInfo.environment}</p>
							<p>Last Updated: {new Date(backendInfo.timestamp).toLocaleString()}</p>
						</div>
					{/if}
				</div>
				<div class="rounded-lg bg-white p-6 shadow-sm">
					<h4 class="mb-2 text-lg font-semibold text-amber-800">Frontend Application</h4>
					<p class="text-amber-600">Running ✅</p>
					<div class="mt-2 text-sm text-amber-500">
						<p>SvelteKit + TailwindCSS</p>
						<p>Development Mode</p>
					</div>
				</div>
			</div>

			{#if configStatus}
				<div class="mt-6 rounded-lg bg-white p-6 shadow-sm">
					<h4 class="mb-3 text-lg font-semibold text-amber-800">Configuration Status</h4>
					<div class="grid gap-2 text-sm">
						<div class="flex justify-between">
							<span class="text-amber-700">Database:</span>
							<span class="text-amber-600">{configStatus.databaseUrl}</span>
						</div>
						<div class="flex justify-between">
							<span class="text-amber-700">Frontend URL:</span>
							<span class="text-amber-600">{configStatus.frontendUrl}</span>
						</div>
						<div class="flex justify-between">
							<span class="text-amber-700">Keycloak:</span>
							<span class="text-amber-600">{configStatus.keycloakUrl}</span>
						</div>
						<div class="flex justify-between">
							<span class="text-amber-700">Auth Client:</span>
							<span class="text-amber-600">{configStatus.keycloakClientId}</span>
						</div>
					</div>
				</div>
			{/if}
		</div>
	</section>
</PageLayout>

<style>
	:global(body) {
		margin: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	}
</style>
