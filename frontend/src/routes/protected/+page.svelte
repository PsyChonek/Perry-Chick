<!--
Protected Chicks Management Page

This page demonstrates authentication-protected content using the AuthGuard component.
Users must be logged in to view and manage chicks.
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import AuthGuard from '$lib/auth/AuthGuard.svelte';
	import { chicksApi, type Chick } from '$lib/apiClient';
	import { isAuthenticated, userInfo } from '$lib/auth/keycloak';

	let chicks: Chick[] = [];
	let loading = false;
	let error: string | null = null;
	let showForm = false;
	let newChick: Partial<Chick> = {
		name: '',
		breed: '',
		color: '',
		weight: 0
	};

	// Load chicks when authenticated
	$: if ($isAuthenticated) {
		loadChicks();
	}

	async function loadChicks() {
		if (!$isAuthenticated) return;

		loading = true;
		error = null;

		try {
			chicks = await chicksApi.getAllChicks();
		} catch (err: any) {
			error = `Failed to load chicks: ${err.message || err}`;
			console.error('Error loading chicks:', err);
		} finally {
			loading = false;
		}
	}

	async function createChick() {
		if (!newChick.name || !newChick.breed) {
			error = 'Name and breed are required';
			return;
		}

		try {
			const chickToCreate: Chick = {
				id: 0,
				name: newChick.name,
				breed: newChick.breed,
				hatchDate: new Date().toISOString(),
				color: newChick.color || '',
				weight: newChick.weight || 0,
				userId: 0, // Will be set by backend
				user: null as any,
				createdAt: new Date().toISOString(),
				updatedAt: null,
				isActive: true
			};

			await chicksApi.createChick({ chick: chickToCreate });

			// Reset form
			newChick = { name: '', breed: '', color: '', weight: 0 };
			showForm = false;

			// Reload chicks
			await loadChicks();
		} catch (err: any) {
			error = `Failed to create chick: ${err.message || err}`;
			console.error('Error creating chick:', err);
		}
	}

	async function deleteChick(id: number, name: string) {
		if (!confirm(`Are you sure you want to delete ${name}?`)) {
			return;
		}

		try {
			await chicksApi.deleteChick({ id });
			chicks = chicks.filter((c) => c.id !== id);
		} catch (err: any) {
			error = `Failed to delete chick: ${err.message || err}`;
			console.error('Error deleting chick:', err);
		}
	}

	function formatDate(dateString: string): string {
		return new Date(dateString).toLocaleDateString();
	}

	function formatWeight(weight: number): string {
		return `${weight.toFixed(1)} lbs`;
	}
</script>

<svelte:head>
	<title>Chick Management - Perry Chick</title>
</svelte:head>

<AuthGuard requireRoles={['farmer', 'admin']}>
	<div class="chick-management">
		<div class="header">
			<h1>🐥 Chick Management</h1>
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
				{showForm ? '❌ Cancel' : '➕ Add New Chick'}
			</button>

			<button on:click={loadChicks} class="btn-secondary" disabled={loading}>
				{loading ? '🔄 Loading...' : '🔄 Refresh'}
			</button>
		</div>

		{#if showForm}
			<div class="form-container">
				<h2>Add New Chick</h2>
				<form on:submit|preventDefault={createChick}>
					<div class="form-grid">
						<div class="form-group">
							<label for="name">Name *</label>
							<input
								id="name"
								type="text"
								bind:value={newChick.name}
								placeholder="Enter chick name"
								required
							/>
						</div>

						<div class="form-group">
							<label for="breed">Breed *</label>
							<input
								id="breed"
								type="text"
								bind:value={newChick.breed}
								placeholder="e.g., Rhode Island Red"
								required
							/>
						</div>

						<div class="form-group">
							<label for="color">Color</label>
							<input
								id="color"
								type="text"
								bind:value={newChick.color}
								placeholder="e.g., Brown"
							/>
						</div>

						<div class="form-group">
							<label for="weight">Weight (lbs)</label>
							<input
								id="weight"
								type="number"
								step="0.1"
								min="0"
								bind:value={newChick.weight}
								placeholder="0.0"
							/>
						</div>
					</div>

					<div class="form-actions">
						<button type="submit" class="btn-success"> ✅ Create Chick </button>
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

		<div class="chicks-section">
			{#if loading}
				<div class="loading">
					<div class="spinner"></div>
					<p>Loading your chicks...</p>
				</div>
			{:else if chicks.length === 0}
				<div class="empty-state">
					<h2>🐣 No chicks yet!</h2>
					<p>Start your flock by adding your first chick.</p>
					<button on:click={() => (showForm = true)} class="btn-primary">
						➕ Add First Chick
					</button>
				</div>
			{:else}
				<div class="chicks-grid">
					{#each chicks as chick (chick.id)}
						<div class="chick-card">
							<div class="chick-header">
								<h3>{chick.name}</h3>
								<button
									on:click={() => deleteChick(chick.id, chick.name)}
									class="delete-btn"
									title="Delete chick"
								>
									🗑️
								</button>
							</div>

							<div class="chick-details">
								<div class="detail-row">
									<span class="label">🐔 Breed:</span>
									<span class="value">{chick.breed}</span>
								</div>

								{#if chick.color}
									<div class="detail-row">
										<span class="label">🎨 Color:</span>
										<span class="value">{chick.color}</span>
									</div>
								{/if}

								<div class="detail-row">
									<span class="label">⚖️ Weight:</span>
									<span class="value">{formatWeight(chick.weight)}</span>
								</div>

								<div class="detail-row">
									<span class="label">🗓️ Hatched:</span>
									<span class="value">{formatDate(chick.hatchDate)}</span>
								</div>

								<div class="detail-row">
									<span class="label">📅 Added:</span>
									<span class="value">{formatDate(chick.createdAt)}</span>
								</div>
							</div>

							<div class="chick-status">
								<span class="status-badge {chick.isActive ? 'active' : 'inactive'}">
									{chick.isActive ? '✅ Active' : '❌ Inactive'}
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
	.chick-management {
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

	.chicks-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
		gap: 1.5rem;
	}

	.chick-card {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
		transition:
			transform 0.2s,
			box-shadow 0.2s;
	}

	.chick-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 15px rgba(0, 0, 0, 0.15);
	}

	.chick-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
		padding-bottom: 0.5rem;
		border-bottom: 2px solid #ecf0f1;
	}

	.chick-header h3 {
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

	.chick-details {
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

	.chick-status {
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
