<!--
Login Button Component

Simple component that shows login/logout button based on authentication state
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import {
		keycloakService,
		isAuthenticated,
		isLoading,
		userInfo,
		authError
	} from '$lib/auth/keycloak';

	onMount(async () => {
		await keycloakService.init();
	});

	async function handleLogin() {
		try {
			await keycloakService.login();
		} catch (error) {
			console.error('Login error:', error);
		}
	}

	async function handleLogout() {
		try {
			await keycloakService.logout();
		} catch (error) {
			console.error('Logout error:', error);
		}
	}
</script>

<div class="auth-widget">
	{#if $isLoading}
		<div class="loading-indicator">
			<div class="spinner"></div>
		</div>
	{:else if $authError}
		<div class="error-message">
			Auth Error: {$authError}
		</div>
	{:else if $isAuthenticated && $userInfo}
		<div class="user-panel">
			<span class="user-greeting">
				👋 {$userInfo.firstName || $userInfo.username}
			</span>
			<button on:click={handleLogout} class="btn-logout"> Logout </button>
		</div>
	{:else}
		<button on:click={handleLogin} class="btn-login"> 🔐 Login </button>
	{/if}
</div>

<style>
	.auth-widget {
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.loading-indicator {
		display: flex;
		align-items: center;
	}

	.spinner {
		width: 20px;
		height: 20px;
		border: 2px solid #f3f3f3;
		border-top: 2px solid #3498db;
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

	.error-message {
		color: #e74c3c;
		font-size: 0.9rem;
		max-width: 200px;
	}

	.user-panel {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.user-greeting {
		color: #2c3e50;
		font-weight: 500;
	}

	.btn-login,
	.btn-logout {
		padding: 0.5rem 1rem;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
		transition: all 0.2s;
	}

	.btn-login {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
	}

	.btn-login:hover {
		transform: translateY(-1px);
		box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
	}

	.btn-logout {
		background: #e74c3c;
		color: white;
	}

	.btn-logout:hover {
		background: #c0392b;
	}
</style>
