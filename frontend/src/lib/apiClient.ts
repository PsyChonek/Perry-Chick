/**
 * Perry Chick API Client Configuration
 *
 * This file provides a configured API client instance for the Perry Chick backend.
 * Import this to use the generated API clients in your Svelte components.
 */

import { Configuration } from './api/runtime';
import { StoreItemsApi } from './api/apis/StoreItemsApi';
import { UsersApi } from './api/apis/UsersApi';
import { HealthApi } from './api/apis/HealthApi';
import { DevelopmentApi } from './api/apis/DevelopmentApi';
import { AuthenticationApi } from './api/apis/AuthenticationApi';
import { ShoppingCartApi } from './api/apis/ShoppingCartApi';
import { keycloakService } from './auth/keycloak';

// API Configuration with Keycloak authentication
const apiConfig = new Configuration({
	basePath: 'http://localhost:5006', // Backend URL
	headers: {
		'Content-Type': 'application/json'
	},
	// Dynamic access token from Keycloak
	accessToken: () => keycloakService.getToken() || ''
});

// Pre-configured API instances
export const storeItemsApi = new StoreItemsApi(apiConfig);
export const usersApi = new UsersApi(apiConfig);
export const healthApi = new HealthApi(apiConfig);
export const developmentApi = new DevelopmentApi(apiConfig);
export const authenticationApi = new AuthenticationApi(apiConfig);
export const shoppingCartApi = new ShoppingCartApi(apiConfig);

// Export the configuration for custom usage
export { apiConfig };

// Export all types and models for convenience
export * from './api';
