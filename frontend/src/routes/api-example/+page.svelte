<!--
Example Svelte component showing how to use the generated API client
This demonstrates fetching chicks from the backend API
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import { chicksApi, type Chick } from '$lib/apiClient';

	let chicks: Chick[] = [];
	let loading = true;
	let error: string | null = null;

	// Fetch chicks when component mounts
	onMount(async () => {
		try {
			const response = await chicksApi.getAllChicks();
			chicks = response;
			loading = false;
		} catch (err) {
			error = `Failed to load chicks: ${err}`;
			loading = false;
		}
	});

	// Create a new chick
	async function createChick() {
		try {
			const newChick: Chick = {
				id: 0, // Will be set by backend
				name: `Chick ${Date.now()}`,
				birthDate: new Date().toISOString(),
				breed: 'Rhode Island Red',
				isHealthy: true
			};

			await chicksApi.createChick({ chick: newChick });

			// Refresh the list
			const response = await chicksApi.getAllChicks();
			chicks = response;
		} catch (err) {
			error = `Failed to create chick: ${err}`;
		}
	}

	// Delete a chick
	async function deleteChick(id: number) {
		try {
			await chicksApi.deleteChick({ id });

			// Remove from local list
			chicks = chicks.filter((c) => c.id !== id);
		} catch (err) {
			error = `Failed to delete chick: ${err}`;
		}
	}
</script>

<div class="chicks-manager">
	<h2>Perry Chick Management</h2>

	{#if error}
		<div class="error">
			{error}
		</div>
	{/if}

	<button on:click={createChick} disabled={loading}> Add New Chick </button>

	{#if loading}
		<p>Loading chicks...</p>
	{:else if chicks.length === 0}
		<p>No chicks found. Add some chicks to get started!</p>
	{:else}
		<div class="chicks-grid">
			{#each chicks as chick (chick.id)}
				<div class="chick-card">
					<h3>{chick.name}</h3>
					<p><strong>Breed:</strong> {chick.breed}</p>
					<p>
						<strong>Birth Date:</strong>
						{new Date(chick.birthDate).toLocaleDateString()}
					</p>
					<p>
						<strong>Health:</strong>
						{chick.isHealthy ? '✅ Healthy' : '❌ Needs Attention'}
					</p>

					<button on:click={() => deleteChick(chick.id)} class="delete-btn">
						Delete
					</button>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.chicks-manager {
		padding: 1rem;
		max-width: 800px;
		margin: 0 auto;
	}

	.error {
		background: #fee;
		border: 1px solid #fcc;
		color: #c33;
		padding: 0.5rem;
		border-radius: 4px;
		margin-bottom: 1rem;
	}

	.chicks-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
		gap: 1rem;
		margin-top: 1rem;
	}

	.chick-card {
		border: 1px solid #ddd;
		border-radius: 8px;
		padding: 1rem;
		background: #f9f9f9;
	}

	.chick-card h3 {
		margin: 0 0 0.5rem 0;
		color: #333;
	}

	.chick-card p {
		margin: 0.25rem 0;
		color: #666;
	}

	.delete-btn {
		background: #dc3545;
		color: white;
		border: none;
		padding: 0.5rem 1rem;
		border-radius: 4px;
		cursor: pointer;
		margin-top: 0.5rem;
	}

	.delete-btn:hover {
		background: #c82333;
	}

	button:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}
</style>
