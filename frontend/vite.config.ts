import tailwindcss from '@tailwindcss/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit()],
	server: {
		proxy: {
			'/api': {
				target: 'http://localhost:5006',
				changeOrigin: true,
				secure: false
			},
			'/health': {
				target: 'http://localhost:5006',
				changeOrigin: true,
				secure: false
			},
			'/config': {
				target: 'http://localhost:5006',
				changeOrigin: true,
				secure: false
			}
		}
	}
});
