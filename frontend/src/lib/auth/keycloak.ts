/**
 * Keycloak Authentication Service
 *
 * This service handles authentication with Keycloak for the Perry Chick application.
 * It provides methods for login, logout, token management, and user information.
 */

import Keycloak, { type KeycloakProfile } from 'keycloak-js';
import { writable, derived } from 'svelte/store';
import { browser } from '$app/environment';
import { replaceState } from '$app/navigation';

// Configuration from environment or defaults
const KC_CONFIG = {
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
	private initialized: boolean = false;

	/**
	 * Initialize Keycloak
	 */
	async init(): Promise<boolean> {
		if (!browser) return false;

		// Prevent multiple initializations
		if (this.initialized) {
			console.log('Keycloak already initialized');
			return this.keycloak?.authenticated || false;
		}

		try {
			isLoading.set(true);
			authError.set(null);

			// Note: Keycloak.js may show a SvelteKit warning about using history.replaceState()
			// This is internal to Keycloak and cannot be avoided. The warning can be safely ignored.

			// Create Keycloak instance
			this.keycloak = new Keycloak({
				url: KC_CONFIG.url,
				realm: KC_CONFIG.realm,
				clientId: KC_CONFIG.clientId
			});

			// Initialize Keycloak with better error handling
			const authenticated = await this.keycloak.init({
				onLoad: 'check-sso',
				checkLoginIframe: false, // Disable iframe checks to avoid sandbox warnings
				checkLoginIframeInterval: 0, // Disable periodic iframe checks
				enableLogging: false, // Disable verbose logging
				pkceMethod: 'S256',
				// Add response mode to avoid URL fragments
				responseMode: 'query',
				// Prevent Keycloak from manipulating browser history
				flow: 'standard'
			});

			this.initialized = true;

			// Update stores
			keycloakInstance.set(this.keycloak);
			isAuthenticated.set(authenticated);

			if (authenticated) {
				await this.loadUserInfo();
				this.setupTokenRefresh();
			}

			// Setup event listeners
			this.setupEventListeners();

			// Clean up auth parameters from URL after successful initialization
			if (
				window.location.search.includes('state=') ||
				window.location.search.includes('code=') ||
				window.location.search.includes('session_state=')
			) {
				console.log('Cleaning auth parameters from URL');
				// Use SvelteKit's replaceState to avoid conflicts with router
				try {
					replaceState('', {});
				} catch (error) {
					console.warn('Failed to clean URL with SvelteKit replaceState:', error);
					// Fallback: just log the issue, don't break authentication
				}
			}

			console.log('Keycloak initialized successfully. Authenticated:', authenticated);
			return authenticated;
		} catch (error) {
			console.error('Failed to initialize Keycloak:', error);

			// Don't set error state if it's just a normal "not authenticated" state
			if (error && error.toString().includes('login_required')) {
				console.log('User not authenticated - this is normal');
				isAuthenticated.set(false);
			} else {
				authError.set(`Authentication service unavailable. Please try again later.`);
			}
			this.initialized = true; // Mark as initialized even if failed
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

		// First try to use token information directly (more reliable)
		if (this.keycloak?.tokenParsed) {
			const tokenProfile = {
				id: this.keycloak.tokenParsed.sub,
				username:
					this.keycloak.tokenParsed.preferred_username || this.keycloak.tokenParsed.name,
				email: this.keycloak.tokenParsed.email,
				firstName: this.keycloak.tokenParsed.given_name,
				lastName: this.keycloak.tokenParsed.family_name,
				emailVerified: this.keycloak.tokenParsed.email_verified
			};
			console.log('Using profile from token:', tokenProfile);
			userInfo.set(tokenProfile);
			authError.set(null);
			return;
		}

		// Fallback: try to load from profile endpoint
		try {
			const profile = await this.keycloak.loadUserProfile();
			console.log('Loaded user profile from endpoint:', profile);
			userInfo.set(profile);
		} catch (error) {
			console.error('Failed to load user profile from endpoint:', error);
			// This is expected to fail sometimes, so we don't set an error
			// since we already have the token information above
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
export { KC_CONFIG, KeycloakService };
