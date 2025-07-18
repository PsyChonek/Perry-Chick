// Import auto-generated API models
import type { User as ApiUser, StoreItem, ShoppingCartItem } from './api/models';

// Re-export API models for convenience
export type { StoreItem, ShoppingCartItem };
export type User = ApiUser;

// Frontend-specific types that don't exist in the backend
export interface UserInfo {
	userId?: number;
	email?: string;
	username?: string;
	isAuthenticated: boolean;
	roles: string[];
}

export interface AuthState {
	isAuthenticated: boolean;
	isLoading: boolean;
	user: UserInfo | null;
	error: string | null;
}

// ShoppingCart interface until it's properly exported from API
export interface ShoppingCart {
	id: number;
	userId: number;
	createdAt: string;
	updatedAt?: string;
	isActive: boolean;
	items: ShoppingCartItem[];
}

export interface ApiResponse<T> {
	data?: T;
	success: boolean;
	message?: string;
	error?: string;
	status?: number;
}

export interface HealthCheck {
	status: string;
	timestamp: string;
	version: string;
}

export interface ApiConfig {
	message: string;
	version: string;
	environment: string;
	timestamp: string;
}

export interface ConfigStatus {
	databaseUrl: string;
	frontendUrl: string;
	keycloakUrl: string;
	keycloakClientId: string;
}
