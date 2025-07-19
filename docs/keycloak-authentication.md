# Keycloak Authentication Implementation

This document explains the Keycloak authentication implementation for the Perry Chick application.

## Overview

The authentication system uses Keycloak as the identity provider with the following components:

- **Keycloak Server**: Running locally on port 8080
- **Frontend Integration**: Keycloak JavaScript adapter with Svelte stores
- **Backend Validation**: JWT token validation in the .NET API
- **Role-based Access**: Different roles for admin, farmer, and regular users

## Setup and Configuration

### 1. Start Keycloak Locally

```bash
# Using VS Code task (recommended)
Ctrl+Shift+P -> "Tasks: Run Task" -> "Start Local Keycloak"

# Or using script directly
.\scripts\keycloak.ps1
```

### 2. Access Keycloak Admin Console

- **URL**: http://localhost:8080/admin
- **Username**: admin
- **Password**: admin_password_change_me

### 3. Realm Configuration

The script automatically creates a `perrychick` realm with:

- **Client ID**: `perrychick-frontend`
- **Redirect URIs**:
  - `http://localhost:3000/*` (SvelteKit dev)
  - `http://localhost:5173/*` (Vite dev)
- **Web Origins**: `http://localhost:3000`, `http://localhost:5173`

### 4. Test Users

The realm includes pre-configured test users:

| Username  | Password    | Roles        | Description                |
| --------- | ----------- | ------------ | -------------------------- |
| `admin`   | `admin123`  | admin, user  | Full administrative access |
| `farmer1` | `farmer123` | farmer, user | Chick management access    |

## Frontend Implementation

### Core Authentication Service

The `keycloak.ts` service provides:

```typescript
import { keycloakService, isAuthenticated, userInfo } from "$lib/auth/keycloak";

// Initialize authentication
await keycloakService.init();

// Login
await keycloakService.login();

// Logout
await keycloakService.logout();

// Check authentication status
$isAuthenticated; // Svelte store

// Get user information
$userInfo; // Svelte store
```

### Authentication Stores

| Store             | Type              | Description                         |
| ----------------- | ----------------- | ----------------------------------- |
| `isAuthenticated` | `boolean`         | Whether user is logged in           |
| `isLoading`       | `boolean`         | Authentication initialization state |
| `userInfo`        | `KeycloakProfile` | User profile information            |
| `authError`       | `string`          | Authentication error messages       |
| `accessToken`     | `string`          | Current JWT access token            |
| `userRoles`       | `string[]`        | User's assigned roles               |

### AuthGuard Component

Protects routes and components with authentication:

```svelte
<script>
	import AuthGuard from '$lib/auth/AuthGuard.svelte';
</script>

<!-- Basic authentication required -->
<AuthGuard>
	<ProtectedContent />
</AuthGuard>

<!-- Require specific roles -->
<AuthGuard requireRoles={['farmer', 'admin']}>
	<AdminContent />
</AuthGuard>
```

### LoginButton Component

Simple login/logout widget:

```svelte
<script>
	import LoginButton from '$lib/components/LoginButton.svelte';
</script>

<LoginButton />
```

## API Integration

### Authenticated API Calls

The API client automatically includes JWT tokens:

```typescript
import { chicksApi } from "$lib/apiClient";

// API calls automatically include Bearer token
const chicks = await chicksApi.getAllChicks();
```

### Manual Authentication

For custom API calls:

```typescript
import { keycloakService } from "$lib/auth/keycloak";

const response = await keycloakService.authenticatedFetch("/api/custom", {
  method: "POST",
  body: JSON.stringify(data),
});
```

## Backend Configuration

### JWT Validation

The backend validates JWT tokens from Keycloak:

```csharp
// In Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = Environment.GetEnvironmentVariable("KC_AUTHORITY_URL");
        options.Audience = Environment.GetEnvironmentVariable("KC_CLIENT_ID");
        options.RequireHttpsMetadata = false; // Development only

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = Environment.GetEnvironmentVariable("KC_ISSUERS_URL"),
            // ... other validation parameters
        };
    });
```

### Protected Endpoints

Controllers use `[Authorize]` attributes:

```csharp
[Authorize] // Requires authentication
[Authorize(Roles = "admin")] // Requires specific role
public class ChicksController : ControllerBase
{
    // Protected endpoints
}
```

## Usage Examples

### Page-Level Protection

```svelte
<!-- routes/protected/+page.svelte -->
<script>
	import AuthGuard from '$lib/auth/AuthGuard.svelte';
</script>

<AuthGuard requireRoles={['farmer', 'admin']}>
	<h1>Farmer Dashboard</h1>
	<!-- Protected content -->
</AuthGuard>
```

### Component-Level Protection

```svelte
<!-- Any component -->
<script>
	import { isAuthenticated, userRoles } from '$lib/auth/keycloak';

	$: isAdmin = $userRoles.includes('admin');
</script>

{#if $isAuthenticated}
	<p>Welcome, authenticated user!</p>

	{#if isAdmin}
		<button>Admin Action</button>
	{/if}
{/if}
```

### API Error Handling

```typescript
import { chicksApi } from "$lib/apiClient";

try {
  const chicks = await chicksApi.getAllChicks();
} catch (error) {
  if (error.response?.status === 401) {
    // Token expired, redirect to login
    await keycloakService.login();
  } else {
    console.error("API Error:", error);
  }
}
```

## Environment Configuration

### Frontend Environment

Update `src/lib/auth/keycloak.ts`:

```typescript
const KC_CONFIG = {
  url:
    process.env.NODE_ENV === "production"
      ? "https://auth.perrychick.com"
      : "http://localhost:8080",
  realm: "perrychick",
  clientId: "perrychick-frontend",
};
```

### Backend Environment

Set environment variables in `.env.local`:

```bash
KC_AUTHORITY_URL=http://localhost:8080
KC_ISSUERS_URL=http://localhost:8080
KC_REALM=perrychick
KC_CLIENT_ID=perrychick-frontend
KC_CLIENT_SECRET=your_client_secret_here
```

## Roles and Permissions

### Available Roles

| Role     | Description   | Permissions               |
| -------- | ------------- | ------------------------- |
| `user`   | Basic user    | Read access to own data   |
| `farmer` | Farmer role   | CRUD operations on chicks |
| `admin`  | Administrator | Full system access        |

### Role-based Components

```svelte
<script>
	import { userRoles } from '$lib/auth/keycloak';

	$: canManageChicks = $userRoles.some(role => ['farmer', 'admin'].includes(role));
	$: isAdmin = $userRoles.includes('admin');
</script>

{#if canManageChicks}
	<ChickManagement />
{/if}

{#if isAdmin}
	<AdminPanel />
{/if}
```

## Token Management

### Automatic Refresh

Tokens are automatically refreshed every 5 minutes:

```typescript
// Automatic token refresh is handled by the service
// No manual intervention required
```

### Manual Refresh

Force token refresh:

```typescript
import { keycloakService } from "$lib/auth/keycloak";

try {
  await keycloakService.keycloak.updateToken(30); // Refresh if expires in 30 seconds
} catch (error) {
  // Refresh failed, redirect to login
  await keycloakService.login();
}
```

## Security Considerations

### Development vs Production

- **Development**: Uses HTTP, disabled HTTPS requirements
- **Production**: Should use HTTPS, enable all security features

### CORS Configuration

Ensure backend CORS allows your frontend domain:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("Development", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});
```

## Troubleshooting

### Common Issues

#### 1. Keycloak Not Starting

```bash
# Check Docker
docker ps
docker logs perrychick-keycloak-local

# Restart Keycloak
.\scripts\keycloak.ps1 -Force
```

#### 2. Authentication Fails

- Check Keycloak realm configuration
- Verify client redirect URIs
- Ensure backend JWT validation is configured

#### 3. CORS Errors

- Update backend CORS policy
- Check frontend URL configuration

#### 4. Token Expired

- Automatic refresh should handle this
- Check browser console for errors

### Debug Authentication

```typescript
import { keycloakService } from "$lib/auth/keycloak";

// Enable Keycloak logging
// Set enableLogging: true in keycloak.init()

// Check token
console.log("Token:", keycloakService.getToken());

// Check user roles
console.log("Roles:", keycloakService.keycloak?.realmAccess?.roles);
```

## Testing Authentication

### Test Login Flow

1. Start Keycloak: `.\scripts\keycloak.ps1`
2. Start Frontend: `npm run dev`
3. Visit: http://localhost:3000/protected
4. Click "Login with Keycloak"
5. Use test credentials: `admin` / `admin123`

### Test Protected Routes

- `/protected` - Requires farmer or admin role
- `/api-example` - Basic authentication demo

### Test API Integration

```javascript
// Browser console
await fetch("/api/chicks", {
  headers: {
    Authorization: `Bearer ${keycloakService.getToken()}`,
  },
});
```

## VS Code Tasks

| Task                   | Command                                                   | Description              |
| ---------------------- | --------------------------------------------------------- | ------------------------ |
| Start Local Keycloak   | `Ctrl+Shift+P` → Tasks: Run Task → Start Local Keycloak   | Start Keycloak container |
| Stop Local Keycloak    | `Ctrl+Shift+P` → Tasks: Run Task → Stop Local Keycloak    | Stop Keycloak container  |
| Restart Local Keycloak | `Ctrl+Shift+P` → Tasks: Run Task → Restart Local Keycloak | Force restart Keycloak   |

## Next Steps

1. **Configure Production Keycloak**: Set up Keycloak for production environment
2. **Implement User Registration**: Add user registration flow
3. **Add Social Login**: Configure OAuth2 providers (Google, GitHub, etc.)
4. **Implement User Management**: Admin interface for user management
5. **Add Audit Logging**: Track authentication events
6. **Configure Email**: Set up email verification and password reset

## References

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak JavaScript Adapter](https://www.keycloak.org/docs/latest/securing_apps/#_javascript_adapter)
- [SvelteKit Authentication](https://kit.svelte.dev/docs/routing#advanced-routing-hooks)
- [JWT Bearer Authentication in ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/security/authentication/jwt-authz)
