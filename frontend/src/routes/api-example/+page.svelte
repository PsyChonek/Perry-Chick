<!--
API Example Page

This page demonstrates how to use the various APIs available in the Perry Chick application.
It shows examples of authentication, CRUD operations, and error handling.
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import { storeItemsApi, usersApi, healthApi } from '$lib/apiClient';
	import type { StoreItem, User } from '$lib/api';
	import { isAuthenticated, userInfo } from '$lib/auth/keycloak';

	// State
	let loading = false;
	let error: string | null = null;
	let healthStatus: any = null;
	let storeItems: StoreItem[] = [];
	let users: User[] = [];
	let selectedExample = 'health';

	// Example data for creating items
	let newItem = {
		name: 'Example Item',
		description: 'This is a test item created from the API example',
		price: 9.99,
		stock: 10
	};

	onMount(() => {
		checkHealth();
	});

	async function checkHealth() {
		loading = true;
		error = null;
		try {
			const response = await healthApi.healthCheck();
			healthStatus = response;
		} catch (err: any) {
			error = `Health check failed: ${err.message || err}`;
			console.error('Health check error:', err);
		} finally {
			loading = false;
		}
	}

	async function loadStoreItems() {
		if (!$isAuthenticated) {
			error = 'You must be authenticated to access store items';
			return;
		}

		loading = true;
		error = null;
		try {
			const response = await storeItemsApi.getStoreItems();
			storeItems = response;
		} catch (err: any) {
			error = `Failed to load store items: ${err.message || err}`;
			console.error('Store items error:', err);
		} finally {
			loading = false;
		}
	}

	async function createExampleItem() {
		if (!$isAuthenticated) {
			error = 'You must be authenticated to create items';
			return;
		}

		loading = true;
		error = null;
		try {
			const itemToCreate: StoreItem = {
				id: 0,
				name: newItem.name,
				description: newItem.description,
				price: newItem.price,
				stock: newItem.stock,
				createdAt: new Date(),
				updatedAt: null,
				isActive: true
			};

			await storeItemsApi.createStoreItem({ storeItem: itemToCreate });
			await loadStoreItems(); // Refresh the list
		} catch (err: any) {
			error = `Failed to create item: ${err.message || err}`;
			console.error('Create item error:', err);
		} finally {
			loading = false;
		}
	}

	async function loadUsers() {
		if (!$isAuthenticated) {
			error = 'You must be authenticated to access users';
			return;
		}

		loading = true;
		error = null;
		try {
			const response = await usersApi.getUsers();
			users = response;
		} catch (err: any) {
			error = `Failed to load users: ${err.message || err}`;
			console.error('Users error:', err);
		} finally {
			loading = false;
		}
	}

	function formatJson(obj: any): string {
		return JSON.stringify(obj, null, 2);
	}

	function clearResults() {
		error = null;
		healthStatus = null;
		storeItems = [];
		users = [];
	}
</script>

<svelte:head>
	<title>API Examples - Perry Chick</title>
</svelte:head>

<div class="api-examples">
	<div class="header">
		<h1>🔧 API Examples</h1>
		<p>Interactive examples of using the Perry Chick APIs</p>
	</div>

	<div class="auth-status">
		{#if $isAuthenticated}
			<div class="status authenticated">
				✅ Authenticated as {$userInfo?.username || 'Unknown'}
			</div>
		{:else}
			<div class="status unauthenticated">
				❌ Not authenticated - some examples require login
			</div>
		{/if}
	</div>

	{#if error}
		<div class="error-banner">
			<strong>Error:</strong>
			{error}
			<button on:click={() => (error = null)} class="close-btn">×</button>
		</div>
	{/if}

	<div class="examples-container">
		<div class="sidebar">
			<h3>Examples</h3>
			<nav>
				<button
					class="nav-btn {selectedExample === 'health' ? 'active' : ''}"
					on:click={() => (selectedExample = 'health')}
				>
					🏥 Health Check
				</button>
				<button
					class="nav-btn {selectedExample === 'items' ? 'active' : ''}"
					on:click={() => (selectedExample = 'items')}
				>
					🏪 Store Items
				</button>
				<button
					class="nav-btn {selectedExample === 'users' ? 'active' : ''}"
					on:click={() => (selectedExample = 'users')}
				>
					👥 Users
				</button>
				<button
					class="nav-btn {selectedExample === 'create' ? 'active' : ''}"
					on:click={() => (selectedExample = 'create')}
				>
					➕ Create Item
				</button>
			</nav>
		</div>

		<div class="content">
			{#if selectedExample === 'health'}
				<div class="example-section">
					<h2>Health Check API</h2>
					<p>Test the backend health endpoint (no authentication required)</p>

					<div class="actions">
						<button on:click={checkHealth} disabled={loading} class="btn-primary">
							{loading ? '⏳ Checking...' : '🔍 Check Health'}
						</button>
						<button on:click={clearResults} class="btn-secondary">Clear</button>
					</div>

					{#if healthStatus}
						<div class="result">
							<h3>Response:</h3>
							<pre>{formatJson(healthStatus)}</pre>
						</div>
					{/if}
				</div>
			{:else if selectedExample === 'items'}
				<div class="example-section">
					<h2>Store Items API</h2>
					<p>Load all store items (requires authentication)</p>

					<div class="actions">
						<button
							on:click={loadStoreItems}
							disabled={loading || !$isAuthenticated}
							class="btn-primary"
						>
							{loading ? '⏳ Loading...' : '📦 Load Items'}
						</button>
						<button on:click={clearResults} class="btn-secondary">Clear</button>
					</div>

					{#if storeItems.length > 0}
						<div class="result">
							<h3>Store Items ({storeItems.length}):</h3>
							<div class="items-grid">
								{#each storeItems as item}
									<div class="item-card">
										<h4>{item.name}</h4>
										<p>{item.description}</p>
										<div class="item-details">
											<span>💲 ${item.price?.toFixed(2) || '0.00'}</span>
											<span>📦 Stock: {item.stock || 0}</span>
										</div>
									</div>
								{/each}
							</div>
						</div>
					{/if}
				</div>
			{:else if selectedExample === 'users'}
				<div class="example-section">
					<h2>Users API</h2>
					<p>Load all users (requires authentication)</p>

					<div class="actions">
						<button
							on:click={loadUsers}
							disabled={loading || !$isAuthenticated}
							class="btn-primary"
						>
							{loading ? '⏳ Loading...' : '👥 Load Users'}
						</button>
						<button on:click={clearResults} class="btn-secondary">Clear</button>
					</div>

					{#if users.length > 0}
						<div class="result">
							<h3>Users ({users.length}):</h3>
							<pre>{formatJson(users)}</pre>
						</div>
					{/if}
				</div>
			{:else if selectedExample === 'create'}
				<div class="example-section">
					<h2>Create Store Item</h2>
					<p>Create a new store item (requires authentication)</p>

					<div class="form-container">
						<div class="form-grid">
							<div class="form-group">
								<label for="name">Name:</label>
								<input
									id="name"
									type="text"
									bind:value={newItem.name}
									placeholder="Item name"
								/>
							</div>
							<div class="form-group">
								<label for="description">Description:</label>
								<input
									id="description"
									type="text"
									bind:value={newItem.description}
									placeholder="Item description"
								/>
							</div>
							<div class="form-group">
								<label for="price">Price:</label>
								<input
									id="price"
									type="number"
									step="0.01"
									bind:value={newItem.price}
									placeholder="0.00"
								/>
							</div>
							<div class="form-group">
								<label for="stock">Stock:</label>
								<input
									id="stock"
									type="number"
									bind:value={newItem.stock}
									placeholder="0"
								/>
							</div>
						</div>

						<div class="actions">
							<button
								on:click={createExampleItem}
								disabled={loading || !$isAuthenticated}
								class="btn-success"
							>
								{loading ? '⏳ Creating...' : '➕ Create Item'}
							</button>
						</div>
					</div>

					{#if storeItems.length > 0}
						<div class="result">
							<h3>Recently Created Items:</h3>
							<div class="items-grid">
								{#each storeItems.slice(0, 3) as item}
									<div class="item-card">
										<h4>{item.name}</h4>
										<p>{item.description}</p>
									</div>
								{/each}
							</div>
						</div>
					{/if}
				</div>
			{/if}
		</div>
	</div>
</div>

<style>
	.api-examples {
		max-width: 1200px;
		margin: 0 auto;
		padding: 2rem;
	}

	.header {
		text-align: center;
		margin-bottom: 2rem;
	}

	.header h1 {
		color: #2c3e50;
		margin: 0 0 0.5rem 0;
		font-size: 2.5rem;
	}

	.header p {
		color: #7f8c8d;
		font-size: 1.1rem;
		margin: 0;
	}

	.auth-status {
		margin-bottom: 2rem;
		text-align: center;
	}

	.status {
		display: inline-block;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
	}

	.status.authenticated {
		background: #d5f4e6;
		color: #27ae60;
	}

	.status.unauthenticated {
		background: #fdeaea;
		color: #e74c3c;
	}

	.error-banner {
		background: #fee;
		border: 1px solid #fcc;
		color: #c33;
		padding: 1rem;
		border-radius: 8px;
		margin-bottom: 1rem;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.close-btn {
		background: none;
		border: none;
		font-size: 1.5rem;
		cursor: pointer;
		color: #c33;
	}

	.examples-container {
		display: grid;
		grid-template-columns: 250px 1fr;
		gap: 2rem;
	}

	.sidebar {
		background: white;
		padding: 1.5rem;
		border-radius: 12px;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
		height: fit-content;
	}

	.sidebar h3 {
		margin: 0 0 1rem 0;
		color: #2c3e50;
	}

	.sidebar nav {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.nav-btn {
		padding: 0.75rem 1rem;
		border: none;
		border-radius: 6px;
		background: #f8f9fa;
		color: #495057;
		cursor: pointer;
		transition: all 0.2s;
		text-align: left;
		font-weight: 500;
	}

	.nav-btn:hover {
		background: #e9ecef;
	}

	.nav-btn.active {
		background: #3498db;
		color: white;
	}

	.content {
		background: white;
		padding: 2rem;
		border-radius: 12px;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
	}

	.example-section h2 {
		margin: 0 0 0.5rem 0;
		color: #2c3e50;
	}

	.example-section p {
		color: #7f8c8d;
		margin: 0 0 1.5rem 0;
	}

	.actions {
		display: flex;
		gap: 1rem;
		margin-bottom: 1.5rem;
	}

	.btn-primary,
	.btn-secondary,
	.btn-success {
		padding: 0.75rem 1.5rem;
		border: none;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.btn-primary {
		background: #3498db;
		color: white;
	}

	.btn-primary:hover:not(:disabled) {
		background: #2980b9;
	}

	.btn-secondary {
		background: #95a5a6;
		color: white;
	}

	.btn-secondary:hover {
		background: #7f8c8d;
	}

	.btn-success {
		background: #27ae60;
		color: white;
	}

	.btn-success:hover:not(:disabled) {
		background: #229954;
	}

	button:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.form-container {
		background: #f8f9fa;
		padding: 1.5rem;
		border-radius: 8px;
		margin-bottom: 1.5rem;
	}

	.form-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
		margin-bottom: 1rem;
	}

	.form-group {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.form-group label {
		font-weight: 600;
		color: #34495e;
	}

	.form-group input {
		padding: 0.5rem;
		border: 2px solid #ecf0f1;
		border-radius: 4px;
		font-size: 1rem;
	}

	.form-group input:focus {
		outline: none;
		border-color: #3498db;
	}

	.result {
		margin-top: 1.5rem;
	}

	.result h3 {
		margin: 0 0 1rem 0;
		color: #2c3e50;
	}

	.result pre {
		background: #f8f9fa;
		padding: 1rem;
		border-radius: 6px;
		overflow-x: auto;
		font-size: 0.9rem;
		border: 1px solid #e9ecef;
	}

	.items-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 1rem;
	}

	.item-card {
		background: #f8f9fa;
		padding: 1rem;
		border-radius: 6px;
		border: 1px solid #e9ecef;
	}

	.item-card h4 {
		margin: 0 0 0.5rem 0;
		color: #2c3e50;
	}

	.item-card p {
		margin: 0 0 0.5rem 0;
		color: #7f8c8d;
		font-size: 0.9rem;
	}

	.item-details {
		display: flex;
		gap: 1rem;
		font-size: 0.9rem;
		color: #495057;
	}

	@media (max-width: 768px) {
		.examples-container {
			grid-template-columns: 1fr;
		}

		.sidebar {
			order: 2;
		}

		.content {
			order: 1;
		}
	}
</style>
