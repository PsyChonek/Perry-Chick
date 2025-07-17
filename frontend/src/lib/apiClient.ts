/**
 * Perry Chick API Client Configuration
 *
 * This file provides a configured API client instance for the Perry Chick backend.
 * Import this to use the generated API clients in your Svelte components.
 */

import { Configuration } from './api/runtime';
import { ChicksApi } from './api/apis/ChicksApi';
import { UsersApi } from './api/apis/UsersApi';
import { HealthApi } from './api/apis/HealthApi';
import { DevelopmentApi } from './api/apis/DevelopmentApi';
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
export const chicksApi = new ChicksApi(apiConfig);
export const usersApi = new UsersApi(apiConfig);
export const healthApi = new HealthApi(apiConfig);
export const developmentApi = new DevelopmentApi(apiConfig);

// Export the configuration for custom usage
export { apiConfig };

// Export all types and models for convenience
export * from './api';
