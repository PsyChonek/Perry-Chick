import { handler } from './build/handler.js';
import express from 'express';

const app = express();
const port = process.env.PORT || 3000;

// Use SvelteKit handler for all requests
app.use(handler);

app.listen(port, '0.0.0.0', () => {
	console.log(`Server running on http://0.0.0.0:${port}`);
});
