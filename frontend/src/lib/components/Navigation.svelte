<!--
Navigation Component with Authentication

Reusable navigation bar that includes authentication status
-->

<script lang="ts">
	import LoginButton from '$lib/components/LoginButton.svelte';
	import { isAuthenticated } from '$lib/auth/keycloak';

	export let currentPage = '';
</script>

<nav class="hidden items-center space-x-6 md:flex">
	<a
		href="/"
		class="font-medium text-amber-700 hover:text-amber-900 {currentPage === 'home'
			? 'font-semibold text-amber-900'
			: ''}"
	>
		Home
	</a>

	<a
		href="/api-example"
		class="font-medium text-amber-700 hover:text-amber-900 {currentPage === 'api-example'
			? 'font-semibold text-amber-900'
			: ''}"
	>
		API Demo
	</a>

	{#if $isAuthenticated}
		<a
			href="/protected"
			class="font-medium text-amber-700 hover:text-amber-900 {currentPage === 'protected'
				? 'font-semibold text-amber-900'
				: ''}"
		>
			🐥 Chick Management
		</a>
	{/if}

	<div class="border-l border-amber-300 pl-6">
		<LoginButton />
	</div>
</nav>

<style>
	/* Mobile menu could be added here in the future */
</style>
