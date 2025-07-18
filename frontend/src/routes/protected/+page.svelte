<!--
Protected Store Management Page

This page demonstrates authentication-protected content using the AuthGuard component.
Users must be logged in to view and manage store items.
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import AuthGuard from '$lib/auth/AuthGuard.svelte';
	import { storeItemsApi } from '$lib/apiClient';
	import type { StoreItem } from '$lib/api';
	import { isAuthenticated, userInfo } from '$lib/auth/keycloak';

	let storeItems: StoreItem[] = [];
	let loading = false;
	let error: string | null = null;
	let showForm = false;
	let newItem: Partial<StoreItem> = {
		name: '',
		description: '',
		price: 0,
		stock: 0
	};

	// Load store items when authenticated
	$: if ($isAuthenticated) {
		loadStoreItems();
	}

	async function loadStoreItems() {
		if (!$isAuthenticated) return;

		loading = true;
		error = null;

		try {
			const response = await storeItemsApi.getStoreItems();
			storeItems = response;
		} catch (err: any) {
			error = `Failed to load items: ${err.message || err}`;
			console.error('Error loading store items:', err);
		} finally {
			loading = false;
		}
	}

	async function createStoreItem() {
		if (!newItem.name || !newItem.description) {
			error = 'Name and description are required';
			return;
		}

		try {
			const itemToCreate: StoreItem = {
				id: 0,
				name: newItem.name,
				description: newItem.description,
				price: newItem.price || 0,
				stock: newItem.stock || 0,
				createdAt: new Date(),
				updatedAt: null,
				isActive: true
			};

			await storeItemsApi.createStoreItem({ storeItem: itemToCreate });

			// Reset form
			newItem = { name: '', description: '', price: 0, stock: 0 };
			showForm = false;

			// Reload items
			await loadStoreItems();
		} catch (err: any) {
			error = `Failed to create item: ${err.message || err}`;
			console.error('Error creating store item:', err);
		}
	}

	async function deleteStoreItem(id: number | undefined, name: string | undefined) {
		if (!id || !name) return;

		if (!confirm(`Are you sure you want to delete ${name}?`)) {
			return;
		}

		try {
			await storeItemsApi.deleteStoreItem({ id });
			storeItems = storeItems.filter((item) => item.id !== id);
		} catch (err: any) {
			error = `Failed to delete item: ${err.message || err}`;
			console.error('Error deleting store item:', err);
		}
	}

	function formatDate(date: Date | string): string {
		const dateObj = typeof date === 'string' ? new Date(date) : date;
		return dateObj.toLocaleDateString();
	}

	function formatPrice(price: number | null | undefined): string {
		if (price == null) return '0.00';
		return price.toFixed(2);
	}
</script>

<svelte:head>
	<title>Store Management - Perry Chick</title>
</svelte:head>

<AuthGuard requireRoles={['farmer', 'admin']}>
	<div class="store-management">
		<div class="header">
			<h1>� Store Management</h1>
			{#if $userInfo}
				<p class="welcome">Welcome back, {$userInfo.firstName || $userInfo.username}!</p>
			{/if}
		</div>

		{#if error}
			<div class="error-banner">
				{error}
				<button on:click={() => (error = null)} class="close-btn">×</button>
			</div>
		{/if}

		<div class="actions">
			<button on:click={() => (showForm = !showForm)} class="btn-primary" disabled={loading}>
				{showForm ? '❌ Cancel' : '➕ Add New Item'}
			</button>

			<button on:click={loadStoreItems} class="btn-secondary" disabled={loading}>
				{loading ? '🔄 Loading...' : '🔄 Refresh'}
			</button>
		</div>

		{#if showForm}
			<div class="form-container">
				<h2>Add New Store Item</h2>
				<form on:submit|preventDefault={createStoreItem}>
					<div class="form-grid">
						<div class="form-group">
							<label for="name">Name *</label>
							<input
								id="name"
								type="text"
								bind:value={newItem.name}
								placeholder="Enter item name"
								required
							/>
						</div>

						<div class="form-group">
							<label for="description">Description *</label>
							<input
								id="description"
								type="text"
								bind:value={newItem.description}
								placeholder="Enter item description"
								required
							/>
						</div>

						<div class="form-group">
							<label for="price">Price ($)</label>
							<input
								id="price"
								type="number"
								step="0.01"
								min="0"
								bind:value={newItem.price}
								placeholder="0.00"
							/>
						</div>

						<div class="form-group">
							<label for="stock">Stock Quantity</label>
							<input
								id="stock"
								type="number"
								min="0"
								bind:value={newItem.stock}
								placeholder="0"
							/>
						</div>
					</div>

					<div class="form-actions">
						<button type="submit" class="btn-success"> ✅ Create Item </button>
						<button
							type="button"
							on:click={() => (showForm = false)}
							class="btn-cancel"
						>
							❌ Cancel
						</button>
					</div>
				</form>
			</div>
		{/if}

		<div class="items-section">
			{#if loading}
				<div class="loading">
					<div class="spinner"></div>
					<p>Loading your store items...</p>
				</div>
			{:else if storeItems.length === 0}
				<div class="empty-state">
					<h2>🏪 No items yet!</h2>
					<p>Start your store by adding your first item.</p>
					<button on:click={() => (showForm = true)} class="btn-primary">
						➕ Add First Item
					</button>
				</div>
			{:else}
				<div class="items-grid">
					{#each storeItems as item (item.id)}
						<div class="item-card">
							<div class="item-header">
								<h3>{item.name}</h3>
								<button
									on:click={() => item.id && deleteStoreItem(item.id, item.name)}
									class="delete-btn"
									title="Delete item"
								>
									🗑️
								</button>
							</div>

							<div class="item-details">
								<div class="detail-row">
									<span class="label">� Description:</span>
									<span class="value">{item.description}</span>
								</div>

								<div class="detail-row">
									<span class="label">💲 Price:</span>
									<span class="value">${formatPrice(item.price)}</span>
								</div>

								<div class="detail-row">
									<span class="label">� Stock:</span>
									<span class="value">{item.stock ?? 0}</span>
								</div>

								<div class="detail-row">
									<span class="label">📅 Added:</span>
									<span class="value"
										>{item.createdAt
											? formatDate(item.createdAt)
											: 'Unknown'}</span
									>
								</div>
							</div>

							<div class="item-status">
								<span
									class="status-badge {(item.stock ?? 0) > 0
										? 'active'
										: 'inactive'}"
								>
									{(item.stock ?? 0) > 0 ? '✅ In Stock' : '❌ Out of Stock'}
								</span>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	</div>
</AuthGuard>

<style>
	.store-management {
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

	.welcome {
		color: #7f8c8d;
		font-size: 1.1rem;
		margin: 0;
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

	.actions {
		display: flex;
		gap: 1rem;
		margin-bottom: 2rem;
		justify-content: center;
	}

	.btn-primary,
	.btn-secondary,
	.btn-success,
	.btn-cancel {
		padding: 0.75rem 1.5rem;
		border: none;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		font-size: 1rem;
	}

	.btn-primary {
		background: linear-gradient(135deg, #3498db, #2980b9);
		color: white;
	}

	.btn-primary:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(52, 152, 219, 0.4);
	}

	.btn-secondary {
		background: #95a5a6;
		color: white;
	}

	.btn-secondary:hover:not(:disabled) {
		background: #7f8c8d;
	}

	.btn-success {
		background: #27ae60;
		color: white;
	}

	.btn-success:hover {
		background: #229954;
	}

	.btn-cancel {
		background: #e74c3c;
		color: white;
	}

	.btn-cancel:hover {
		background: #c0392b;
	}

	button:disabled {
		opacity: 0.6;
		cursor: not-allowed;
		transform: none !important;
	}

	.form-container {
		background: white;
		padding: 2rem;
		border-radius: 12px;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
		margin-bottom: 2rem;
	}

	.form-container h2 {
		margin: 0 0 1.5rem 0;
		color: #2c3e50;
	}

	.form-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 1.5rem;
		margin-bottom: 2rem;
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
		padding: 0.75rem;
		border: 2px solid #ecf0f1;
		border-radius: 6px;
		font-size: 1rem;
		transition: border-color 0.2s;
	}

	.form-group input:focus {
		outline: none;
		border-color: #3498db;
	}

	.form-actions {
		display: flex;
		gap: 1rem;
		justify-content: flex-end;
	}

	.loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		min-height: 200px;
		gap: 1rem;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #f3f3f3;
		border-top: 4px solid #3498db;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		0% {
			transform: rotate(0deg);
		}
		100% {
			transform: rotate(360deg);
		}
	}

	.empty-state {
		text-align: center;
		padding: 4rem 2rem;
		background: #f8f9fa;
		border-radius: 12px;
	}

	.empty-state h2 {
		color: #2c3e50;
		margin: 0 0 1rem 0;
	}

	.empty-state p {
		color: #7f8c8d;
		margin: 0 0 2rem 0;
		font-size: 1.1rem;
	}

	.items-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
		gap: 1.5rem;
	}

	.item-card {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
		transition:
			transform 0.2s,
			box-shadow 0.2s;
	}

	.item-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 15px rgba(0, 0, 0, 0.15);
	}

	.item-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
		padding-bottom: 0.5rem;
		border-bottom: 2px solid #ecf0f1;
	}

	.item-header h3 {
		margin: 0;
		color: #2c3e50;
		font-size: 1.3rem;
	}

	.delete-btn {
		background: none;
		border: none;
		font-size: 1.2rem;
		cursor: pointer;
		padding: 0.25rem;
		border-radius: 4px;
		transition: background-color 0.2s;
	}

	.delete-btn:hover {
		background: #fee;
	}

	.item-details {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		margin-bottom: 1rem;
	}

	.detail-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.label {
		font-weight: 600;
		color: #7f8c8d;
	}

	.value {
		color: #2c3e50;
	}

	.item-status {
		display: flex;
		justify-content: center;
	}

	.status-badge {
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
		font-size: 0.9rem;
		font-weight: 600;
	}

	.status-badge.active {
		background: #d5f4e6;
		color: #27ae60;
	}

	.status-badge.inactive {
		background: #fdeaea;
		color: #e74c3c;
	}
</style>
