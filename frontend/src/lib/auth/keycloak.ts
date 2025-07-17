/**
 * Keycloak Authentication Service
 *
 * This service handles authentication with Keycloak for the Perry Chick application.
 * It provides methods for login, logout, token management, and user information.
 */

import Keycloak, { type KeycloakProfile } from 'keycloak-js';
import { writable, derived, get } from 'svelte/store';
import { browser } from '$app/environment';

// Configuration from environment or defaults
const KEYCLOAK_CONFIG = {
	url: 'http://localhost:8080',
	realm: 'perrychick',
	clientId: 'perrychick-frontend'
};

// Stores for authentication state
export const keycloakInstance = writable<Keycloak | null>(null);
export const isAuthenticated = writable<boolean>(false);
export const isLoading = writable<boolean>(true);
export const userInfo = writable<KeycloakProfile | null>(null);
export const authError = writable<string | null>(null);

// Derived store for token
export const accessToken = derived(keycloakInstance, ($keycloak) => {
	return $keycloak?.token || null;
});

// Derived store for user roles
export const userRoles = derived(keycloakInstance, ($keycloak) => {
	return $keycloak?.realmAccess?.roles || [];
});

class KeycloakService {
	private keycloak: Keycloak | null = null;
	private refreshTokenInterval: number | null = null;

	/**
	 * Initialize Keycloak
	 */
	async init(): Promise<boolean> {
		if (!browser) return false;

		try {
			isLoading.set(true);
			authError.set(null);

			// Create Keycloak instance
			this.keycloak = new Keycloak({
				url: KEYCLOAK_CONFIG.url,
				realm: KEYCLOAK_CONFIG.realm,
				clientId: KEYCLOAK_CONFIG.clientId
			});

			// Initialize Keycloak
			const authenticated = await this.keycloak.init({
				onLoad: 'check-sso',
				silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
				checkLoginIframe: false, // Disable for development
				enableLogging: true,
				pkceMethod: 'S256'
			});

			// Update stores
			keycloakInstance.set(this.keycloak);
			isAuthenticated.set(authenticated);

			if (authenticated) {
				await this.loadUserInfo();
				this.setupTokenRefresh();
			}

			// Setup event listeners
			this.setupEventListeners();

			console.log('Keycloak initialized. Authenticated:', authenticated);
			return authenticated;
		} catch (error) {
			console.error('Failed to initialize Keycloak:', error);
			authError.set(`Failed to initialize authentication: ${error}`);
			return false;
		} finally {
			isLoading.set(false);
		}
	}

	/**
	 * Login with redirect to Keycloak
	 */
	async login(): Promise<void> {
		if (!this.keycloak) {
			throw new Error('Keycloak not initialized');
		}

		try {
			await this.keycloak.login({
				redirectUri: window.location.origin
			});
		} catch (error) {
			console.error('Login failed:', error);
			authError.set(`Login failed: ${error}`);
			throw error;
		}
	}

	/**
	 * Logout and redirect to Keycloak
	 */
	async logout(): Promise<void> {
		if (!this.keycloak) {
			throw new Error('Keycloak not initialized');
		}

		try {
			// Clear token refresh
			if (this.refreshTokenInterval) {
				clearInterval(this.refreshTokenInterval);
				this.refreshTokenInterval = null;
			}

			// Logout from Keycloak
			await this.keycloak.logout({
				redirectUri: window.location.origin
			});

			// Update stores
			isAuthenticated.set(false);
			userInfo.set(null);
			authError.set(null);
		} catch (error) {
			console.error('Logout failed:', error);
			authError.set(`Logout failed: ${error}`);
			throw error;
		}
	}

	/**
	 * Get current access token
	 */
	getToken(): string | null {
		return this.keycloak?.token || null;
	}

	/**
	 * Check if user has a specific role
	 */
	hasRole(role: string): boolean {
		return this.keycloak?.hasRealmRole(role) || false;
	}

	/**
	 * Check if user has any of the specified roles
	 */
	hasAnyRole(roles: string[]): boolean {
		return roles.some((role) => this.hasRole(role));
	}

	/**
	 * Get user profile information
	 */
	async loadUserInfo(): Promise<void> {
		if (!this.keycloak?.authenticated) return;

		try {
			const profile = await this.keycloak.loadUserProfile();
			userInfo.set(profile);
		} catch (error) {
			console.error('Failed to load user info:', error);
			authError.set(`Failed to load user info: ${error}`);
		}
	}

	/**
	 * Setup automatic token refresh
	 */
	private setupTokenRefresh(): void {
		if (!this.keycloak) return;

		// Refresh token every 5 minutes
		this.refreshTokenInterval = window.setInterval(
			async () => {
				try {
					if (this.keycloak?.authenticated) {
						const refreshed = await this.keycloak.updateToken(30); // Refresh if expires in 30 seconds
						if (refreshed) {
							console.log('Token refreshed');
						}
					}
				} catch (error) {
					console.error('Failed to refresh token:', error);
					authError.set('Session expired. Please login again.');
					await this.logout();
				}
			},
			5 * 60 * 1000
		); // 5 minutes
	}

	/**
	 * Setup Keycloak event listeners
	 */
	private setupEventListeners(): void {
		if (!this.keycloak) return;

		this.keycloak.onAuthSuccess = () => {
			console.log('Authentication successful');
			isAuthenticated.set(true);
			authError.set(null);
			this.loadUserInfo();
			this.setupTokenRefresh();
		};

		this.keycloak.onAuthError = (error) => {
			console.error('Authentication error:', error);
			authError.set(`Authentication error: ${error}`);
			isAuthenticated.set(false);
		};

		this.keycloak.onAuthLogout = () => {
			console.log('User logged out');
			isAuthenticated.set(false);
			userInfo.set(null);
			if (this.refreshTokenInterval) {
				clearInterval(this.refreshTokenInterval);
				this.refreshTokenInterval = null;
			}
		};

		this.keycloak.onTokenExpired = () => {
			console.log('Token expired, attempting refresh');
			this.keycloak?.updateToken(30).catch(() => {
				console.log('Failed to refresh expired token, logging out');
				this.logout();
			});
		};
	}

	/**
	 * Get authorization header for API calls
	 */
	getAuthHeader(): Record<string, string> {
		const token = this.getToken();
		return token ? { Authorization: `Bearer ${token}` } : {};
	}

	/**
	 * Create authenticated fetch function
	 */
	authenticatedFetch = async (url: string, options: RequestInit = {}): Promise<Response> => {
		const authHeaders = this.getAuthHeader();

		return fetch(url, {
			...options,
			headers: {
				...options.headers,
				...authHeaders
			}
		});
	};
}

// Create singleton instance
export const keycloakService = new KeycloakService();

// Helper function to ensure Keycloak is initialized
export async function ensureKeycloakInit(): Promise<boolean> {
	if (!browser) return false;

	const $keycloak = keycloakInstance;
	let currentKeycloak: Keycloak | null = null;
	const unsubscribe = $keycloak.subscribe((value) => (currentKeycloak = value));
	unsubscribe();

	if (!currentKeycloak) {
		return await keycloakService.init();
	}
	return true;
}

// Export for use in components
export { KEYCLOAK_CONFIG, KeycloakService };
