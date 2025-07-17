<!--
Authentication Guard Component

This component wraps content that requires authentication.
It handles the authentication state and shows appropriate UI.
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import {
		keycloakService,
		isAuthenticated,
		isLoading,
		authError,
		userInfo
	} from '$lib/auth/keycloak';

	export let showLoginButton = true;
	export let requireRoles: string[] = [];

	let hasRequiredRoles = true;

	onMount(async () => {
		await keycloakService.init();

		// Check roles if specified
		if (requireRoles.length > 0) {
			hasRequiredRoles = keycloakService.hasAnyRole(requireRoles);
		}
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

{#if $isLoading}
	<div class="auth-loading">
		<div class="spinner"></div>
		<p>Checking authentication...</p>
	</div>
{:else if $authError}
	<div class="auth-error">
		<h3>Authentication Error</h3>
		<p>{$authError}</p>
		{#if showLoginButton}
			<button on:click={handleLogin} class="btn-primary"> Try Again </button>
		{/if}
	</div>
{:else if !$isAuthenticated}
	<div class="auth-required">
		<div class="auth-card">
			<h2>🔐 Authentication Required</h2>
			<p>Please log in to access this content.</p>

			{#if showLoginButton}
				<button on:click={handleLogin} class="btn-login"> 🚀 Login with Keycloak </button>
			{/if}
		</div>
	</div>
{:else if !hasRequiredRoles}
	<div class="auth-forbidden">
		<div class="auth-card">
			<h2>🚫 Access Denied</h2>
			<p>You don't have the required permissions to access this content.</p>
			<p class="role-info">Required roles: {requireRoles.join(', ')}</p>

			<div class="user-actions">
				<button on:click={handleLogout} class="btn-secondary"> Logout </button>
			</div>
		</div>
	</div>
{:else}
	<!-- User is authenticated and has required roles -->
	<div class="auth-header">
		{#if $userInfo}
			<div class="user-info">
				<span class="user-name">👋 Hello, {$userInfo.firstName || $userInfo.username}</span>
				<button on:click={handleLogout} class="btn-logout"> Logout </button>
			</div>
		{/if}
	</div>

	<slot />
{/if}

<style>
	.auth-loading {
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

	.auth-required,
	.auth-forbidden,
	.auth-error {
		display: flex;
		align-items: center;
		justify-content: center;
		min-height: 400px;
		padding: 2rem;
	}

	.auth-card {
		background: white;
		padding: 2rem;
		border-radius: 12px;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
		text-align: center;
		max-width: 400px;
		width: 100%;
	}

	.auth-card h2 {
		margin: 0 0 1rem 0;
		color: #333;
		font-size: 1.5rem;
	}

	.auth-card p {
		margin: 0 0 1.5rem 0;
		color: #666;
		line-height: 1.5;
	}

	.role-info {
		font-size: 0.9rem;
		color: #888;
		font-style: italic;
	}

	.btn-login {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		padding: 0.75rem 2rem;
		border-radius: 8px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition:
			transform 0.2s,
			box-shadow 0.2s;
	}

	.btn-login:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	.btn-primary {
		background: #3498db;
		color: white;
		border: none;
		padding: 0.5rem 1.5rem;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
	}

	.btn-primary:hover {
		background: #2980b9;
	}

	.btn-secondary {
		background: #95a5a6;
		color: white;
		border: none;
		padding: 0.5rem 1.5rem;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
	}

	.btn-secondary:hover {
		background: #7f8c8d;
	}

	.auth-header {
		background: #f8f9fa;
		border-bottom: 1px solid #dee2e6;
		padding: 1rem;
		margin-bottom: 2rem;
	}

	.user-info {
		display: flex;
		justify-content: space-between;
		align-items: center;
		max-width: 1200px;
		margin: 0 auto;
	}

	.user-name {
		font-weight: 500;
		color: #333;
	}

	.btn-logout {
		background: #dc3545;
		color: white;
		border: none;
		padding: 0.5rem 1rem;
		border-radius: 4px;
		cursor: pointer;
		font-size: 0.9rem;
	}

	.btn-logout:hover {
		background: #c82333;
	}

	.user-actions {
		margin-top: 1rem;
	}

	.auth-error {
		background: #fff5f5;
		border: 1px solid #fed7d7;
		color: #c53030;
	}

	.auth-error .auth-card {
		background: #fff5f5;
		border: 1px solid #fed7d7;
	}

	.auth-error h3 {
		color: #c53030;
		margin: 0 0 1rem 0;
	}
</style>
