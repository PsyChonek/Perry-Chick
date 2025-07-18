<script lang="ts">
	import '../app.css';
	import Header from '$lib/components/Header.svelte';
	import Footer from '$lib/components/Footer.svelte';
	import { onMount } from 'svelte';
	import { keycloakService } from '$lib/auth/keycloak';

	let { children } = $props();

	// Initialize Keycloak once in the root layout
	onMount(async () => {
		try {
			await keycloakService.init();
		} catch (error) {
			console.error('Failed to initialize authentication:', error);
		}
	});
</script>

<div class="flex min-h-screen flex-col">
	<Header />

	<main class="flex-1">
		{@render children()}
	</main>

	<Footer />
</div>
