import { writable } from 'svelte/store';
import { browser } from '$app/environment';
import { api } from './api.js';
import type { User } from './types.js';

export interface AuthState {
	isAuthenticated: boolean;
	token: string | null;
	user: User | null;
	loading: boolean;
}

const initialState: AuthState = {
	isAuthenticated: false,
	token: null,
	user: null,
	loading: false
};

function createAuthStore() {
	const { subscribe, set, update } = writable<AuthState>(initialState);

	return {
		subscribe,

		// Initialize auth state from localStorage
		init() {
			if (browser) {
				const token = localStorage.getItem('auth_token');
				if (token) {
					api.setToken(token);
					update((state) => ({
						...state,
						isAuthenticated: true,
						token
					}));
				}
			}
		},

		// Login with token
		login(token: string, user?: User | null) {
			api.setToken(token);
			update((state) => ({
				...state,
				isAuthenticated: true,
				token,
				user: user || null
			}));
		},

		// Logout
		logout() {
			api.clearToken();
			set(initialState);
		},

		// Set loading state
		setLoading(loading: boolean) {
			update((state) => ({ ...state, loading }));
		},

		// Set user data
		setUser(user: User | null) {
			update((state) => ({ ...state, user }));
		}
	};
}

export const authStore = createAuthStore();

// Initialize on module load
if (browser) {
	authStore.init();
}
