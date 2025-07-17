import { browser } from '$app/environment';
import type { ApiResponse, User, Chick, HealthCheck, ApiConfig, ConfigStatus } from './types.js';

// API Configuration
const API_BASE_URL = browser
	? window.location.hostname === 'localhost'
		? 'http://localhost:5006'
		: `${window.location.protocol}//${window.location.hostname}:5006`
	: 'http://localhost:5006';

class ApiClient {
	private baseUrl: string;
	private token: string | null = null;

	constructor(baseUrl: string) {
		this.baseUrl = baseUrl;

		// Load token from localStorage if available
		if (browser) {
			this.token = localStorage.getItem('auth_token');
		}
	}

	setToken(token: string) {
		this.token = token;
		if (browser) {
			localStorage.setItem('auth_token', token);
		}
	}

	clearToken() {
		this.token = null;
		if (browser) {
			localStorage.removeItem('auth_token');
		}
	}

	private async request<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
		const url = `${this.baseUrl}${endpoint}`;

		const headers: Record<string, string> = {
			'Content-Type': 'application/json',
			...((options.headers as Record<string, string>) || {})
		};

		// Add authorization header if token exists
		if (this.token) {
			headers['Authorization'] = `Bearer ${this.token}`;
		}

		try {
			const response = await fetch(url, {
				...options,
				headers
			});

			const status = response.status;

			if (!response.ok) {
				let errorMessage = `HTTP ${status}`;
				try {
					const errorData = await response.json();
					errorMessage = errorData.message || errorMessage;
				} catch {
					errorMessage = (await response.text()) || errorMessage;
				}

				return {
					error: errorMessage,
					status
				};
			}

			// Handle empty responses (like 204 No Content)
			if (status === 204 || response.headers.get('content-length') === '0') {
				return { status } as ApiResponse<T>;
			}

			const data = await response.json();
			return {
				data,
				status
			};
		} catch (error) {
			return {
				error: error instanceof Error ? error.message : 'Network error',
				status: 0
			};
		}
	}

	// Health endpoints
	async getHealth(): Promise<ApiResponse<HealthCheck>> {
		return this.request<HealthCheck>('/health');
	}

	async getRoot(): Promise<ApiResponse<ApiConfig>> {
		return this.request<ApiConfig>('/');
	}

	async getConfig(): Promise<ApiResponse<ConfigStatus>> {
		return this.request<ConfigStatus>('/config');
	}

	// User endpoints
	async getUsers(): Promise<ApiResponse<User[]>> {
		return this.request<User[]>('/api/users');
	}

	async getUser(id: number): Promise<ApiResponse<User>> {
		return this.request<User>(`/api/users/${id}`);
	}

	async createUser(
		user: Omit<User, 'id' | 'createdAt' | 'updatedAt'>
	): Promise<ApiResponse<User>> {
		return this.request<User>('/api/users', {
			method: 'POST',
			body: JSON.stringify(user)
		});
	}

	async updateUser(
		id: number,
		user: Partial<Omit<User, 'id' | 'createdAt'>>
	): Promise<ApiResponse<void>> {
		return this.request<void>(`/api/users/${id}`, {
			method: 'PUT',
			body: JSON.stringify(user)
		});
	}

	async deleteUser(id: number): Promise<ApiResponse<void>> {
		return this.request<void>(`/api/users/${id}`, {
			method: 'DELETE'
		});
	}

	// Chick endpoints
	async getChicks(): Promise<ApiResponse<Chick[]>> {
		return this.request<Chick[]>('/api/chicks');
	}

	async getChick(id: number): Promise<ApiResponse<Chick>> {
		return this.request<Chick>(`/api/chicks/${id}`);
	}

	async createChick(
		chick: Omit<Chick, 'id' | 'createdAt' | 'updatedAt' | 'user'>
	): Promise<ApiResponse<Chick>> {
		return this.request<Chick>('/api/chicks', {
			method: 'POST',
			body: JSON.stringify(chick)
		});
	}

	async updateChick(
		id: number,
		chick: Partial<Omit<Chick, 'id' | 'createdAt' | 'user'>>
	): Promise<ApiResponse<void>> {
		return this.request<void>(`/api/chicks/${id}`, {
			method: 'PUT',
			body: JSON.stringify(chick)
		});
	}

	async deleteChick(id: number): Promise<ApiResponse<void>> {
		return this.request<void>(`/api/chicks/${id}`, {
			method: 'DELETE'
		});
	}

	async getChicksByUser(userId: number): Promise<ApiResponse<Chick[]>> {
		return this.request<Chick[]>(`/api/users/${userId}/chicks`);
	}
}

// Export singleton instance
export const apiClient = new ApiClient(API_BASE_URL);

// Export the class for testing or multiple instances
export { ApiClient };

// Convenience functions
export const api = {
	// Health
	health: () => apiClient.getHealth(),
	root: () => apiClient.getRoot(),
	config: () => apiClient.getConfig(),

	// Auth
	setToken: (token: string) => apiClient.setToken(token),
	clearToken: () => apiClient.clearToken(),

	// Users
	users: {
		list: () => apiClient.getUsers(),
		get: (id: number) => apiClient.getUser(id),
		create: (user: Omit<User, 'id' | 'createdAt' | 'updatedAt'>) => apiClient.createUser(user),
		update: (id: number, user: Partial<Omit<User, 'id' | 'createdAt'>>) =>
			apiClient.updateUser(id, user),
		delete: (id: number) => apiClient.deleteUser(id)
	},

	// Chicks
	chicks: {
		list: () => apiClient.getChicks(),
		get: (id: number) => apiClient.getChick(id),
		create: (chick: Omit<Chick, 'id' | 'createdAt' | 'updatedAt' | 'user'>) =>
			apiClient.createChick(chick),
		update: (id: number, chick: Partial<Omit<Chick, 'id' | 'createdAt' | 'user'>>) =>
			apiClient.updateChick(id, chick),
		delete: (id: number) => apiClient.deleteChick(id),
		byUser: (userId: number) => apiClient.getChicksByUser(userId)
	}
};
