// TypeScript types matching the C# backend models

export interface User {
	id: number;
	name: string;
	email: string;
	createdAt: string;
	updatedAt?: string;
	isActive: boolean;
}

export interface Chick {
	id: number;
	name: string;
	breed: string;
	hatchDate: string;
	color: string;
	weight: number;
	userId: number;
	user?: User;
	createdAt: string;
	updatedAt?: string;
	isActive: boolean;
}

export interface ApiResponse<T> {
	data?: T;
	error?: string;
	status: number;
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
