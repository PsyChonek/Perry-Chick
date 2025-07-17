<script>
	import { onMount } from 'svelte';

	let apiStatus = 'Checking...';

	onMount(async () => {
		try {
			const response = await fetch('/api/health');
			if (response.ok) {
				apiStatus = 'Connected ✅';
			} else {
				apiStatus = 'Backend Unavailable ❌';
			}
		} catch (error) {
			apiStatus = 'Backend Unavailable ❌';
		}
	});
</script>

<svelte:head>
	<title>Perry Chick - Premium Snacks & Delights</title>
	<meta
		name="description"
		content="Welcome to Perry Chick - Your premier destination for gourmet popcorn and ham"
	/>
</svelte:head>

<main class="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100">
	<!-- Header -->
	<header class="border-b border-amber-200 bg-white shadow-sm">
		<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
			<div class="flex items-center justify-between py-6">
				<div class="flex items-center">
					<h1 class="text-3xl font-bold text-amber-900">🐥 Perry Chick</h1>
					<span class="ml-3 rounded-full bg-amber-100 px-2 py-1 text-sm text-amber-600"
						>Premium Snacks</span
					>
				</div>
				<nav class="hidden space-x-8 md:flex">
					<a href="/shop" class="font-medium text-amber-700 hover:text-amber-900">Shop</a>
					<a href="/about" class="font-medium text-amber-700 hover:text-amber-900"
						>About</a
					>
					<a href="/contact" class="font-medium text-amber-700 hover:text-amber-900"
						>Contact</a
					>
					<a
						href="/login"
						class="rounded-lg bg-amber-600 px-4 py-2 text-white transition-colors hover:bg-amber-700"
						>Login</a
					>
				</nav>
			</div>
		</div>
	</header>

	<!-- Hero Section -->
	<section class="relative px-4 py-20 sm:px-6 lg:px-8">
		<div class="mx-auto max-w-7xl text-center">
			<h2 class="mb-6 text-5xl font-bold text-amber-900 md:text-6xl">
				Welcome to Perry Chick
			</h2>
			<p class="mx-auto mb-8 max-w-3xl text-xl text-amber-700 md:text-2xl">
				Discover our premium collection of gourmet popcorn and artisanal ham. Quality
				ingredients, exceptional taste, delivered fresh to your door.
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
					<h4 class="mb-2 text-xl font-semibold text-amber-800">Artisanal Ham</h4>
					<p class="text-amber-600">
						Carefully cured and smoked ham using traditional methods for exceptional
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
				</div>
				<div class="rounded-lg bg-white p-6 shadow-sm">
					<h4 class="mb-2 text-lg font-semibold text-amber-800">Frontend Application</h4>
					<p class="text-amber-600">Running ✅</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Footer -->
	<footer class="bg-amber-900 px-4 py-12 text-amber-100 sm:px-6 lg:px-8">
		<div class="mx-auto max-w-7xl text-center">
			<h2 class="mb-4 text-2xl font-bold">🐥 Perry Chick</h2>
			<p class="mb-4">Premium snacks delivered with love</p>
			<div class="flex justify-center space-x-6 text-sm">
				<a href="/privacy" class="transition-colors hover:text-white">Privacy Policy</a>
				<a href="/terms" class="transition-colors hover:text-white">Terms of Service</a>
				<a href="/support" class="transition-colors hover:text-white">Support</a>
			</div>
			<p class="mt-6 text-sm text-amber-300">© 2025 Perry Chick. All rights reserved.</p>
		</div>
	</footer>
</main>

<style>
	:global(body) {
		margin: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	}
</style>
