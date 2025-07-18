<script lang="ts">
	import { onMount } from 'svelte';
	import { storeItemsApi, shoppingCartApi, authenticationApi } from '$lib/apiClient';
	import type { StoreItem, ShoppingCart, ShoppingCartItem } from '$lib/api';
	import type { UserInfo } from '$lib/types';
	import PageLayout from '$lib/components/PageLayout.svelte';

	let storeItems: StoreItem[] = [];
	let cart: ShoppingCart | null = null;
	let userInfo: UserInfo | null = null;
	let loading: boolean = true;
	let error: string | null = null;

	// Form states
	let showItemForm: boolean = false;
	let editingItem: StoreItem | null = null;

	// Form data
	let itemForm: {
		name: string;
		description: string;
		price: number;
		stock: number;
		isActive: boolean;
	} = {
		name: '',
		description: '',
		price: 0,
		stock: 0,
		isActive: true
	};

	onMount(async () => {
		await loadData();
	});

	async function loadData(): Promise<void> {
		loading = true;
		error = null;

		try {
			// Load store items and user info
			const [itemsResponse, userResponse] = await Promise.all([
				api.items.list(),
				api.whoAmI().catch(() => ({ data: null })) // Don't fail if not authenticated
			]);

			if (itemsResponse.data) {
				storeItems = itemsResponse.data;
			} else {
				console.warn('Failed to load items:', itemsResponse.error);
			}

			if (userResponse.data) {
				userInfo = userResponse.data;
				// Load user's cart if authenticated
				const cartResponse = await api.cart.get();
				if (cartResponse.data) {
					cart = cartResponse.data;
				}
			}
		} catch (err: any) {
			error = 'Failed to load data';
			console.error('Load error:', err);
		} finally {
			loading = false;
		}
	}

	async function addToCart(storeItemId: number, quantity: number = 1): Promise<void> {
		if (!userInfo) {
			alert('Please log in to add items to cart');
			return;
		}

		try {
			const response = await api.cart.addItem({ storeItemId, quantity });
			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}

			// Reload cart
			const cartResponse = await api.cart.get();
			if (cartResponse.data) {
				cart = cartResponse.data;
			}
		} catch (err: any) {
			alert(`Error adding to cart: ${err.message}`);
		}
	}

	async function updateCartItemQuantity(itemId: number, quantity: number): Promise<void> {
		if (quantity <= 0) {
			await removeFromCart(itemId);
			return;
		}

		try {
			const response = await api.cart.updateItem(itemId, { quantity });
			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}

			// Reload cart
			const cartResponse = await api.cart.get();
			if (cartResponse.data) {
				cart = cartResponse.data;
			}
		} catch (err: any) {
			alert(`Error updating cart: ${err.message}`);
		}
	}

	async function removeFromCart(itemId: number): Promise<void> {
		try {
			const response = await api.cart.removeItem(itemId);
			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}

			// Reload cart
			const cartResponse = await api.cart.get();
			if (cartResponse.data) {
				cart = cartResponse.data;
			}
		} catch (err: any) {
			alert(`Error removing from cart: ${err.message}`);
		}
	}

	async function clearCart(): Promise<void> {
		if (!confirm('Are you sure you want to clear your cart?')) return;

		try {
			const response = await api.cart.clear();
			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}

			// Reload cart
			const cartResponse = await api.cart.get();
			if (cartResponse.data) {
				cart = cartResponse.data;
			}
		} catch (err: any) {
			alert(`Error clearing cart: ${err.message}`);
		}
	}

	async function saveItem(): Promise<void> {
		try {
			let response;
			if (editingItem) {
				response = await api.items.update(editingItem.id, itemForm);
			} else {
				response = await api.items.create(itemForm);
			}

			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}

			// Reset form and reload data
			resetItemForm();
			await loadData();
		} catch (err: any) {
			alert(`Error saving item: ${err.message}`);
		}
	}

	async function deleteItem(id: number): Promise<void> {
		if (!confirm('Are you sure you want to delete this item?')) return;

		try {
			const response = await api.items.delete(id);
			if (response.error) {
				alert(`Error: ${response.error}`);
				return;
			}
			await loadData();
		} catch (err: any) {
			alert(`Error deleting item: ${err.message}`);
		}
	}

	function editItem(item: StoreItem): void {
		editingItem = item;
		itemForm = {
			name: item.name,
			description: item.description,
			price: item.price,
			stock: item.stock,
			isActive: item.isActive
		};
		showItemForm = true;
	}

	function resetItemForm(): void {
		editingItem = null;
		itemForm = {
			name: '',
			description: '',
			price: 0,
			stock: 0,
			isActive: true
		};
		showItemForm = false;
	}

	function getCartItemQuantity(storeItemId: number): number {
		if (!cart || !cart.items) return 0;
		const item = cart.items.find((item) => item.storeItemId === storeItemId);
		return item ? item.quantity : 0;
	}

	function getCartItem(storeItemId: number): ShoppingCartItem | null {
		if (!cart || !cart.items) return null;
		return cart.items.find((item) => item.storeItemId === storeItemId) || null;
	}

	function getCartTotal(): number {
		if (!cart || !cart.items) return 0;
		return cart.items.reduce((total, item) => {
			return total + item.storeItem.price * item.quantity;
		}, 0);
	}
</script>

<PageLayout
	title="Perry Store - Shop"
	description="Shop at Perry Store for quality items and great service"
	maxWidth="7xl"
>
	<h1 class="mb-8 text-4xl font-bold text-amber-900">Perry Store</h1>

	{#if userInfo}
		<div class="mb-6 rounded-lg bg-amber-100 p-4">
			<p class="text-amber-800">Welcome, {userInfo.username || userInfo.email}!</p>
		</div>
	{:else}
		<div class="mb-6 rounded-lg bg-blue-100 p-4">
			<p class="text-blue-800">Please log in to add items to your cart and make purchases.</p>
		</div>
	{/if}

	{#if loading}
		<div class="text-center">
			<div
				class="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-amber-600 border-r-transparent"
			></div>
			<p class="mt-4 text-amber-700">Loading store...</p>
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
		<div class="grid grid-cols-1 gap-8 lg:grid-cols-3">
			<!-- Store Items -->
			<div class="lg:col-span-2">
				<div class="mb-6 flex items-center justify-between">
					<h2 class="text-2xl font-bold text-amber-900">Available Items</h2>
					{#if userInfo}
						<button
							on:click={() => (showItemForm = true)}
							class="rounded-lg bg-amber-600 px-4 py-2 text-white hover:bg-amber-700"
						>
							Add Item
						</button>
					{/if}
				</div>

				<div class="grid grid-cols-1 gap-6 md:grid-cols-2">
					{#each storeItems as item (item.id)}
						<div class="rounded-lg bg-white p-6 shadow-md">
							<div class="mb-2 flex items-start justify-between">
								<h3 class="text-xl font-semibold text-amber-900">
									{item.name}
								</h3>
								{#if userInfo}
									<div class="flex gap-1">
										<button
											on:click={() => editItem(item)}
											class="text-sm text-amber-600 hover:text-amber-800"
										>
											Edit
										</button>
										<button
											on:click={() => deleteItem(item.id)}
											class="text-sm text-red-600 hover:text-red-800"
										>
											Delete
										</button>
									</div>
								{/if}
							</div>
							<p class="mb-4 text-amber-700">{item.description}</p>
							<div class="mb-4 flex items-center justify-between">
								<span class="text-2xl font-bold text-amber-600"
									>${item.price.toFixed(2)}</span
								>
								<span class="text-sm text-amber-600">Stock: {item.stock}</span>
							</div>

							{#if userInfo}
								<div class="flex items-center gap-2">
									{#if getCartItemQuantity(item.id) > 0}
										{@const cartItem = getCartItem(item.id)}
										{#if cartItem}
											<button
												on:click={() =>
													updateCartItemQuantity(
														cartItem.id,
														getCartItemQuantity(item.id) - 1
													)}
												class="rounded bg-amber-200 px-3 py-1 text-amber-800 hover:bg-amber-300"
											>
												-
											</button>
											<span
												class="rounded bg-amber-100 px-3 py-1 text-amber-800"
											>
												{getCartItemQuantity(item.id)}
											</span>
											<button
												on:click={() =>
													updateCartItemQuantity(
														cartItem.id,
														getCartItemQuantity(item.id) + 1
													)}
												class="rounded bg-amber-200 px-3 py-1 text-amber-800 hover:bg-amber-300"
											>
												+
											</button>
										{/if}
									{:else}
										<button
											on:click={() => addToCart(item.id)}
											class="rounded bg-amber-600 px-4 py-2 text-white hover:bg-amber-700"
											disabled={item.stock === 0}
										>
											{item.stock === 0 ? 'Out of Stock' : 'Add to Cart'}
										</button>
									{/if}
								</div>
							{:else}
								<p class="text-sm text-amber-600">Please log in to purchase</p>
							{/if}
						</div>
					{/each}
				</div>
			</div>

			<!-- Shopping Cart -->
			{#if userInfo}
				<div class="lg:col-span-1">
					<div class="sticky top-4 rounded-lg bg-white p-6 shadow-md">
						<h2 class="mb-4 text-2xl font-bold text-amber-900">Shopping Cart</h2>

						{#if cart && cart.items && cart.items.length > 0}
							<div class="mb-4 space-y-4">
								{#each cart.items as item (item.id)}
									<div
										class="flex items-center justify-between rounded bg-amber-50 p-3"
									>
										<div class="flex-1">
											<h4 class="font-medium text-amber-900">
												{item.storeItem.name}
											</h4>
											<p class="text-sm text-amber-600">
												${item.storeItem.price.toFixed(2)} x {item.quantity}
											</p>
										</div>
										<div class="flex items-center gap-2">
											<button
												on:click={() =>
													updateCartItemQuantity(
														item.id,
														item.quantity - 1
													)}
												class="rounded bg-amber-200 px-2 py-1 text-xs text-amber-800 hover:bg-amber-300"
											>
												-
											</button>
											<span
												class="rounded bg-amber-100 px-2 py-1 text-xs text-amber-800"
											>
												{item.quantity}
											</span>
											<button
												on:click={() =>
													updateCartItemQuantity(
														item.id,
														item.quantity + 1
													)}
												class="rounded bg-amber-200 px-2 py-1 text-xs text-amber-800 hover:bg-amber-300"
											>
												+
											</button>
											<button
												on:click={() => removeFromCart(item.id)}
												class="rounded bg-red-200 px-2 py-1 text-xs text-red-800 hover:bg-red-300"
											>
												×
											</button>
										</div>
									</div>
								{/each}
							</div>

							<div class="border-t pt-4">
								<div class="mb-4 flex items-center justify-between">
									<span class="text-lg font-semibold text-amber-900">Total:</span>
									<span class="text-xl font-bold text-amber-600"
										>${getCartTotal().toFixed(2)}</span
									>
								</div>
								<div class="space-y-2">
									<button
										class="w-full rounded bg-amber-600 py-2 text-white hover:bg-amber-700"
									>
										Checkout
									</button>
									<button
										on:click={clearCart}
										class="w-full rounded bg-amber-200 py-2 text-amber-800 hover:bg-amber-300"
									>
										Clear Cart
									</button>
								</div>
							</div>
						{:else}
							<p class="py-8 text-center text-amber-600">Your cart is empty</p>
						{/if}
					</div>
				</div>
			{/if}
		</div>

		<!-- Add/Edit Item Form -->
		{#if showItemForm}
			<div
				class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4"
			>
				<div class="w-full max-w-md rounded-lg bg-white p-6">
					<h3 class="mb-4 text-lg font-semibold text-amber-800">
						{editingItem ? 'Edit Item' : 'Add New Item'}
					</h3>
					<form on:submit|preventDefault={saveItem} class="space-y-4">
						<div>
							<label for="item-name" class="block text-sm font-medium text-amber-700"
								>Name</label
							>
							<input
								id="item-name"
								bind:value={itemForm.name}
								type="text"
								required
								class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
							/>
						</div>
						<div>
							<label
								for="item-description"
								class="block text-sm font-medium text-amber-700">Description</label
							>
							<textarea
								id="item-description"
								bind:value={itemForm.description}
								required
								rows="3"
								class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
							></textarea>
						</div>
						<div class="grid grid-cols-2 gap-4">
							<div>
								<label
									for="item-price"
									class="block text-sm font-medium text-amber-700">Price</label
								>
								<input
									id="item-price"
									bind:value={itemForm.price}
									type="number"
									step="0.01"
									min="0"
									required
									class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
								/>
							</div>
							<div>
								<label
									for="item-stock"
									class="block text-sm font-medium text-amber-700">Stock</label
								>
								<input
									id="item-stock"
									bind:value={itemForm.stock}
									type="number"
									min="0"
									required
									class="mt-1 block w-full rounded-md border-amber-300 shadow-sm focus:border-amber-500 focus:ring-amber-500"
								/>
							</div>
						</div>
						<div class="flex justify-end gap-2">
							<button
								type="button"
								on:click={resetItemForm}
								class="rounded-lg bg-gray-300 px-4 py-2 text-gray-700 hover:bg-gray-400"
							>
								Cancel
							</button>
							<button
								type="submit"
								class="rounded-lg bg-amber-600 px-4 py-2 text-white hover:bg-amber-700"
							>
								{editingItem ? 'Update' : 'Create'}
							</button>
						</div>
					</form>
				</div>
			</div>
		{/if}
	{/if}
</PageLayout>
