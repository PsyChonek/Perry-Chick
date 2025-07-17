<script>
	import { onMount } from 'svelte';
	import { api } from '$lib';

	let users = [];
	let chicks = [];
	let loading = true;
	let error = null;

	// Form states
	let showUserForm = false;
	let showChickForm = false;
	let editingUser = null;
	let editingChick = null;

	// Form data
	let userForm = { name: '', email: '', isActive: true };
	let chickForm = { name: '', breed: '', hatchDate: '', color: '', weight: 0, userId: 1 };

	onMount(async () => {
		await loadData();
	});

	async function loadData() {
		loading = true;
		error = null;

		try {
			// Load users and chicks
			const [usersResponse, chicksResponse] = await Promise.all([
				api.users.list(),
				api.chicks.list()
			]);

			if (usersResponse.data) {
				users = usersResponse.data;
			} else {
				console.warn('Failed to load users:', usersResponse.error);
			}

			if (chicksResponse.data) {
				chicks = chicksResponse.data;
			} else {
				console.warn('Failed to load chicks:', chicksResponse.error);
			}
		} catch (err) {
			error = 'Failed to load data';
			console.error('Load error:', err);
		} finally {
			loading = false;
		}
	}

	async function saveUser() {
		try {
			let response;
			if (editingUser) {
				response = await api.users.update(editingUser.id, userForm);
			} else {
				response = await api.users.create(userForm);
			}

			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}

			// Reset form and reload data
			resetUserForm();
			await loadData();
		} catch (err) {
			alert(`Error saving user: ${err.message}`);
		}
	}

	async function deleteUser(id) {
		if (!confirm('Are you sure you want to delete this user?')) return;

		try {
			const response = await api.users.delete(id);
			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}
			await loadData();
		} catch (err) {
			alert(`Error deleting user: ${err.message}`);
		}
	}

	async function saveChick() {
		try {
			const chickData = {
				...chickForm,
				weight: parseFloat(chickForm.weight)
			};

			let response;
			if (editingChick) {
				response = await api.chicks.update(editingChick.id, chickData);
			} else {
				response = await api.chicks.create(chickData);
			}

			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}

			resetChickForm();
			await loadData();
		} catch (err) {
			alert(`Error saving chick: ${err.message}`);
		}
	}

	async function deleteChick(id) {
		if (!confirm('Are you sure you want to delete this chick?')) return;

		try {
			const response = await api.chicks.delete(id);
			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}
			await loadData();
		} catch (err) {
			alert(`Error deleting chick: ${err.message}`);
		}
	}

	function editUser(user) {
		editingUser = user;
		userForm = { ...user };
		showUserForm = true;
	}

	function editChick(chick) {
		editingChick = chick;
		chickForm = {
			name: chick.name,
			breed: chick.breed,
			hatchDate: chick.hatchDate.split('T')[0], // Convert to date input format
			color: chick.color,
			weight: chick.weight,
			userId: chick.userId
		};
		showChickForm = true;
	}

	function resetUserForm() {
		userForm = { name: '', email: '', isActive: true };
		editingUser = null;
		showUserForm = false;
	}

	function resetChickForm() {
		chickForm = { name: '', breed: '', hatchDate: '', color: '', weight: 0, userId: 1 };
		editingChick = null;
		showChickForm = false;
	}
</script>

<svelte:head>
	<title>Shop - Perry Chick</title>
</svelte:head>

<main class="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100">
	<!-- Header -->
	<header class="border-b border-amber-200 bg-white shadow-sm">
		<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
			<div class="flex items-center justify-between py-6">
				<div class="flex items-center">
					<h1 class="text-3xl font-bold text-amber-900">🐥 Perry Chick Shop</h1>
				</div>
				<nav class="hidden space-x-8 md:flex">
					<a href="/" class="font-medium text-amber-700 hover:text-amber-900">Home</a>
					<a href="/shop" class="font-medium text-amber-700 hover:text-amber-900">Shop</a>
					<a href="/about" class="font-medium text-amber-700 hover:text-amber-900"
						>About</a
					>
				</nav>
			</div>
		</div>
	</header>

	<div class="container mx-auto px-4 py-8">
		{#if loading}
			<div class="text-center">
				<div
					class="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-amber-600 border-r-transparent"
				></div>
				<p class="mt-4 text-amber-700">Loading data...</p>
			</div>
		{:else if error}
			<div class="rounded-lg bg-red-100 p-4 text-red-700">
				<p>{error}</p>
				<button
					on:click={loadData}
					class="mt-2 rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700"
				>
					Retry
				</button>
			</div>
		{:else}
			<!-- Users Section -->
			<section class="mb-12">
				<div class="mb-6 flex items-center justify-between">
					<h2 class="text-2xl font-bold text-amber-900">Users</h2>
					<button
						on:click={() => (showUserForm = true)}
						class="rounded-lg bg-amber-600 px-4 py-2 text-white hover:bg-amber-700"
					>
						Add User
					</button>
				</div>

				{#if showUserForm}
					<div class="mb-6 rounded-lg bg-white p-6 shadow-sm">
						<h3 class="mb-4 text-lg font-semibold text-amber-800">
							{editingUser ? 'Edit User' : 'Add New User'}
						</h3>
						<form on:submit|preventDefault={saveUser} class="space-y-4">
							<div>
								<label
									for="user-name"
									class="block text-sm font-medium text-amber-700">Name</label
								>
								<input
									id="user-name"
									bind:value={userForm.name}
									type="text"
									required
									class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
								/>
							</div>
							<div>
								<label
									for="user-email"
									class="block text-sm font-medium text-amber-700">Email</label
								>
								<input
									id="user-email"
									bind:value={userForm.email}
									type="email"
									required
									class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
								/>
							</div>
							<div class="flex items-center">
								<input
									id="user-active"
									bind:checked={userForm.isActive}
									type="checkbox"
									class="h-4 w-4 rounded border-amber-300 text-amber-600 focus:ring-amber-500"
								/>
								<label for="user-active" class="ml-2 text-sm text-amber-700"
									>Active</label
								>
							</div>
							<div class="flex gap-2">
								<button
									type="submit"
									class="rounded-lg bg-amber-600 px-4 py-2 text-white hover:bg-amber-700"
								>
									{editingUser ? 'Update' : 'Create'}
								</button>
								<button
									type="button"
									on:click={resetUserForm}
									class="rounded-lg border border-amber-600 px-4 py-2 text-amber-600 hover:bg-amber-50"
								>
									Cancel
								</button>
							</div>
						</form>
					</div>
				{/if}

				<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
					{#each users as user}
						<div class="rounded-lg bg-white p-4 shadow-sm">
							<h3 class="font-semibold text-amber-800">{user.name}</h3>
							<p class="text-sm text-amber-600">{user.email}</p>
							<p class="text-xs text-amber-500">
								Status: {user.isActive ? 'Active' : 'Inactive'}
							</p>
							<p class="text-xs text-amber-500">
								Created: {new Date(user.createdAt).toLocaleDateString()}
							</p>
							<div class="mt-2 flex gap-2">
								<button
									on:click={() => editUser(user)}
									class="text-xs text-amber-600 hover:text-amber-800"
								>
									Edit
								</button>
								<button
									on:click={() => deleteUser(user.id)}
									class="text-xs text-red-600 hover:text-red-800"
								>
									Delete
								</button>
							</div>
						</div>
					{/each}
				</div>
			</section>

			<!-- Chicks Section -->
			<section>
				<div class="mb-6 flex items-center justify-between">
					<h2 class="text-2xl font-bold text-amber-900">Chicks</h2>
					<button
						on:click={() => (showChickForm = true)}
						class="rounded-lg bg-amber-600 px-4 py-2 text-white hover:bg-amber-700"
					>
						Add Chick
					</button>
				</div>

				{#if showChickForm}
					<div class="mb-6 rounded-lg bg-white p-6 shadow-sm">
						<h3 class="mb-4 text-lg font-semibold text-amber-800">
							{editingChick ? 'Edit Chick' : 'Add New Chick'}
						</h3>
						<form on:submit|preventDefault={saveChick} class="space-y-4">
							<div class="grid gap-4 md:grid-cols-2">
								<div>
									<label
										for="chick-name"
										class="block text-sm font-medium text-amber-700">Name</label
									>
									<input
										id="chick-name"
										bind:value={chickForm.name}
										type="text"
										required
										class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
									/>
								</div>
								<div>
									<label
										for="chick-breed"
										class="block text-sm font-medium text-amber-700"
										>Breed</label
									>
									<input
										id="chick-breed"
										bind:value={chickForm.breed}
										type="text"
										class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
									/>
								</div>
								<div>
									<label
										for="chick-hatch-date"
										class="block text-sm font-medium text-amber-700"
										>Hatch Date</label
									>
									<input
										id="chick-hatch-date"
										bind:value={chickForm.hatchDate}
										type="date"
										required
										class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
									/>
								</div>
								<div>
									<label
										for="chick-color"
										class="block text-sm font-medium text-amber-700"
										>Color</label
									>
									<input
										id="chick-color"
										bind:value={chickForm.color}
										type="text"
										class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
									/>
								</div>
								<div>
									<label
										for="chick-weight"
										class="block text-sm font-medium text-amber-700"
										>Weight (grams)</label
									>
									<input
										id="chick-weight"
										bind:value={chickForm.weight}
										type="number"
										step="0.1"
										required
										class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
									/>
								</div>
								<div>
									<label
										for="chick-owner"
										class="block text-sm font-medium text-amber-700"
										>Owner</label
									>
									<select
										id="chick-owner"
										bind:value={chickForm.userId}
										required
										class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
									>
										{#each users as user}
											<option value={user.id}>{user.name}</option>
										{/each}
									</select>
								</div>
							</div>
							<div class="flex gap-2">
								<button
									type="submit"
									class="rounded-lg bg-amber-600 px-4 py-2 text-white hover:bg-amber-700"
								>
									{editingChick ? 'Update' : 'Create'}
								</button>
								<button
									type="button"
									on:click={resetChickForm}
									class="rounded-lg border border-amber-600 px-4 py-2 text-amber-600 hover:bg-amber-50"
								>
									Cancel
								</button>
							</div>
						</form>
					</div>
				{/if}

				<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
					{#each chicks as chick}
						<div class="rounded-lg bg-white p-4 shadow-sm">
							<h3 class="font-semibold text-amber-800">{chick.name}</h3>
							<p class="text-sm text-amber-600">Breed: {chick.breed}</p>
							<p class="text-sm text-amber-600">Color: {chick.color}</p>
							<p class="text-sm text-amber-600">Weight: {chick.weight}g</p>
							<p class="text-xs text-amber-500">
								Hatched: {new Date(chick.hatchDate).toLocaleDateString()}
							</p>
							{#if chick.user}
								<p class="text-xs text-amber-500">Owner: {chick.user.name}</p>
							{/if}
							<div class="mt-2 flex gap-2">
								<button
									on:click={() => editChick(chick)}
									class="text-xs text-amber-600 hover:text-amber-800"
								>
									Edit
								</button>
								<button
									on:click={() => deleteChick(chick.id)}
									class="text-xs text-red-600 hover:text-red-800"
								>
									Delete
								</button>
							</div>
						</div>
					{/each}
				</div>
			</section>
		{/if}
	</div>
</main>

<style>
	.container {
		max-width: 1200px;
	}
</style>
