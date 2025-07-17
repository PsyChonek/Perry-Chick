# OpenAPI Client Generation Guide

This document explains how to generate and use TypeScript API clients from your Perry Chick backend API.

## Overview

The project uses `@openapitools/openapi-generator-cli` to automatically generate TypeScript client code from the backend's OpenAPI/Swagger specification.

## Quick Start

### 1. Generate API Client

```bash
# Using npm script (recommended)
npm run generate-api

# Or using the CLI directly
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:5006/swagger/v1/swagger.json \
  -g typescript-fetch \
  -o ./src/lib/api \
  --additional-properties=typescriptThreePlus=true \
  --skip-validate-spec
```

### 2. Use in Svelte Components

```typescript
// Import the pre-configured API clients
import { chicksApi, usersApi, healthApi } from "$lib/apiClient";
import type { Chick, User } from "$lib/apiClient";

// Use in your component
export async function loadChicks(): Promise<Chick[]> {
  try {
    return await chicksApi.getAllChicks();
  } catch (error) {
    console.error("Failed to load chicks:", error);
    throw error;
  }
}
```

## Available Commands

### NPM Scripts

| Command                     | Description                                  |
| --------------------------- | -------------------------------------------- |
| `npm run generate-api`      | Generate client from running backend         |
| `npm run generate-api-file` | Generate client from local swagger.json file |

### VS Code Tasks

- **"Generate API Client"** - VS Code task that ensures backend is running before generating client

## Generated Structure

```
src/lib/api/
├── apis/
│   ├── ChicksApi.ts      # Chick management endpoints
│   ├── UsersApi.ts       # User management endpoints
│   ├── HealthApi.ts      # Health check endpoints
│   ├── DevelopmentApi.ts # Development utilities
│   └── index.ts
├── models/
│   ├── Chick.ts          # Chick data model
│   ├── User.ts           # User data model
│   └── index.ts
├── runtime.ts            # HTTP client runtime
└── index.ts              # Main exports
```

## Pre-configured Client (`src/lib/apiClient.ts`)

The `apiClient.ts` file provides ready-to-use API instances:

```typescript
import { chicksApi, usersApi, healthApi, developmentApi } from "$lib/apiClient";

// All instances are pre-configured with:
// - Base URL: http://localhost:5006
// - Content-Type: application/json
// - Error handling
```

## Usage Examples

### Basic CRUD Operations

```typescript
import { chicksApi, type Chick } from "$lib/apiClient";

// GET all chicks
const chicks = await chicksApi.getAllChicks();

// GET chick by ID
const chick = await chicksApi.getChickById({ id: 1 });

// POST new chick
const newChick: Chick = {
  name: "Henrietta",
  breed: "Rhode Island Red",
  birthDate: "2024-01-15",
  isHealthy: true,
};
await chicksApi.createChick({ chick: newChick });

// PUT update chick
await chicksApi.updateChick({ id: 1, chick: updatedChick });

// DELETE chick
await chicksApi.deleteChick({ id: 1 });
```

### Error Handling

```typescript
import { chicksApi } from "$lib/apiClient";
import { ResponseError } from "$lib/api";

try {
  const chicks = await chicksApi.getAllChicks();
  return chicks;
} catch (error) {
  if (error instanceof ResponseError) {
    if (error.response.status === 404) {
      console.log("No chicks found");
    } else {
      console.error("API Error:", await error.response.text());
    }
  } else {
    console.error("Network Error:", error);
  }
  throw error;
}
```

### Using with Svelte Stores

```typescript
// stores/chicks.ts
import { writable } from "svelte/store";
import { chicksApi, type Chick } from "$lib/apiClient";

export const chicks = writable<Chick[]>([]);
export const loading = writable(false);
export const error = writable<string | null>(null);

export const chicksStore = {
  subscribe: chicks.subscribe,

  async loadAll() {
    loading.set(true);
    error.set(null);

    try {
      const data = await chicksApi.getAllChicks();
      chicks.set(data);
    } catch (err) {
      error.set(`Failed to load chicks: ${err}`);
    } finally {
      loading.set(false);
    }
  },

  async create(chick: Omit<Chick, "id">) {
    try {
      await chicksApi.createChick({ chick: { ...chick, id: 0 } });
      await this.loadAll(); // Refresh list
    } catch (err) {
      error.set(`Failed to create chick: ${err}`);
      throw err;
    }
  },
};
```

## Configuration

### Base URL Configuration

Update the base URL in `src/lib/apiClient.ts`:

```typescript
const apiConfig = new Configuration({
  basePath:
    process.env.NODE_ENV === "production"
      ? "https://api.perrychick.com"
      : "http://localhost:5006",
  // ...
});
```

### Authentication

Add authentication headers:

```typescript
const apiConfig = new Configuration({
  basePath: "http://localhost:5006",
  headers: {
    "Content-Type": "application/json",
  },
  accessToken: () => {
    // Return your auth token here
    return localStorage.getItem("authToken") || "";
  },
});
```

### Custom Headers

```typescript
const apiConfig = new Configuration({
  basePath: "http://localhost:5006",
  headers: {
    "Content-Type": "application/json",
    "X-API-Version": "1.0",
  },
});
```

## Troubleshooting

### Backend Not Running

Ensure the backend is running on port 5006:

```bash
# In VS Code, run the "Debug Backend" task
# Or manually:
cd backend
dotnet run --configuration Debug
```

### Swagger Validation Errors

The generator includes `--skip-validate-spec` to handle C# anonymous type naming issues. This is safe for development.

### CORS Issues

Ensure your backend has CORS configured for the frontend URL:

```csharp
// In Program.cs
builder.Services.AddCors(options =>
{
    options.AddPolicy("Development", policy =>
    {
        policy.WithOrigins("http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});
```

### Type Errors

Regenerate the client after backend changes:

```bash
npm run generate-api
```

## Advanced Usage

### Custom Generator Options

Modify the generation command in `package.json`:

```json
{
  "scripts": {
    "generate-api": "openapi-generator-cli generate -i http://localhost:5006/swagger/v1/swagger.json -g typescript-fetch -o ./src/lib/api --additional-properties=typescriptThreePlus=true,stringEnums=true,enumPropertyNaming=camelCase --skip-validate-spec"
  }
}
```

### Multiple Environments

Create environment-specific generation scripts:

```json
{
  "scripts": {
    "generate-api:dev": "openapi-generator-cli generate -i http://localhost:5006/swagger/v1/swagger.json -g typescript-fetch -o ./src/lib/api --skip-validate-spec",
    "generate-api:staging": "openapi-generator-cli generate -i https://staging-api.perrychick.com/swagger/v1/swagger.json -g typescript-fetch -o ./src/lib/api --skip-validate-spec",
    "generate-api:prod": "openapi-generator-cli generate -i https://api.perrychick.com/swagger/v1/swagger.json -g typescript-fetch -o ./src/lib/api --skip-validate-spec"
  }
}
```

## Best Practices

1. **Regenerate Regularly**: Regenerate the client whenever the backend API changes
2. **Version Control**: Commit generated files to ensure team consistency
3. **Error Handling**: Always wrap API calls in try-catch blocks
4. **Type Safety**: Use TypeScript types from generated models
5. **Environment Configuration**: Use environment variables for API URLs
6. **Authentication**: Implement proper token management
7. **Loading States**: Show loading indicators during API calls
8. **Caching**: Consider implementing client-side caching for frequently accessed data

## See Also

- [OpenAPI Generator CLI Documentation](https://openapi-generator.tech/docs/generators/typescript-fetch/)
- [SvelteKit Documentation](https://kit.svelte.dev/)
- [Example Component](./src/routes/api-example/+page.svelte)
