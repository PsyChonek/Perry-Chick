# Perry Chick E-Shop - AI Coding Agent Instructions

## Architecture Overview

Perry Chick is a **microservices e-commerce application** running on Kubernetes with the following key components:

- **Frontend**: SvelteKit with TailwindCSS and OpenAPI client generation (`frontend/`)
- **Backend**: C# Minimal API with EF Core (.NET 8) (`backend/`)
- **Notifications**: C# service (minimal implementation) (`notifications/`)
- **Auth**: Keycloak OAuth2/OpenID Connect with custom SvelteKit integration
- **CMS**: Strapi headless CMS
- **Database**: PostgreSQL with EF Core code-first migrations
- **Monitoring**: OpenTelemetry → Jaeger/Prometheus/Grafana
- **Orchestration**: Single `k8s/deploy.yaml` with all services

## Critical Development Workflows

### Local Development

```bash
# Complete Minikube setup (one command for everything)
./scripts/reinitialize-minikube.ps1

# Port forward all services and show URLs
./scripts/forward-all-services.ps1

# Individual service debugging (VS Code tasks available)
- "Debug Backend" (dotnet run in backend/)
- "Debug Frontend" (npm run dev in frontend/)
- "Debug Notifications" (dotnet run in notifications/)
```

**⚠️ Important**: Always run `reinitialize-minikube.ps1` first to start the Kubernetes cluster. Other deployment scripts require Minikube to be running.

### Environment Management

**Critical**: Use `scripts/update-env-config.ps1` to sync `.env.local` → Kubernetes ConfigMaps/Secrets

```bash
# Sync config and restart deployments
./scripts/update-env-config.ps1 -Apply -Restart

# Generate secrets only
./scripts/generate-secrets.ps1
```

## Project-Specific Patterns

### Entity Framework (Backend)

- **Code-first**: Define models in `backend/Models/`, migrations auto-generated
- **Context**: `backend/Data/AppDbContext.cs` with seeded demo data
- **Current Models**: `User`, `StoreItem`
- **Pattern**: PostgreSQL with precision decimals, UTC timestamps, cascade deletes
- **Relationships**: `StoreItem.UserId` → `User.Id` with cascade delete

### SvelteKit Frontend Architecture

- **Auth Guard Pattern**: `AuthGuard.svelte` component wraps protected routes
- **API Client**: Auto-generated from OpenAPI via `npm run generate-api`
- **Auth Integration**: Custom Keycloak service in `src/lib/auth/keycloak.ts`
- **Store Pattern**: Svelte stores for auth state (`isAuthenticated`, `userInfo`, etc.)
- **Component Structure**: Reusable components in `src/lib/components/`

### Authentication Implementation

- **Keycloak Config**: Hardcoded to `localhost:8080/perrychick` realm
- **Frontend Flow**: OAuth2 redirect → JWT validation → Svelte stores
- **Backend JWT**: Validates against Keycloak authority, audience-based
- **User Info**: Loads profile from Keycloak, stores in reactive stores
- **Role Checking**: `keycloakService.hasAnyRole()` for permission logic

### Configuration Loading

- **Backend**: Loads `../.env.local` from parent directory using DotNetEnv
- **K8s**: ConfigMap (non-sensitive) + Secrets (passwords/keys) auto-generated from `.env.local`
- **Frontend**: Environment passed via build process
- **Critical**: Never edit `k8s/configmap.yaml` manually - it's generated from `.env.local`
- **Sync Script**: `scripts/update-env-config.ps1` manages ConfigMap/Secret sync

### VS Code Integration

- **Tasks**: Pre-configured for all services (`Debug Backend`, `Debug Frontend`, etc.)
- **Background Tasks**: Use `isBackground: true` for long-running services
- **Port Forwarding**: `Forward All Services` task handles all Kubernetes port forwards
- **Task Dependencies**: `Generate API Client` depends on `Debug Backend` running

### Monitoring & Observability

- **Grafana Dashboards**: Pre-configured in `monitoring/grafana/dashboards/`
  - Business metrics (orders, revenue)
  - Database performance
  - Notifications queue health
- **Access**: Grafana at `localhost:3001`, Jaeger at `localhost:16686`

### Container Strategy

- **Public Images**: All services use public Docker Hub images
- **Single Deploy**: Everything in `k8s/deploy.yaml` for one-command deployment
- **Resource Limits**: Configured for local Minikube (256Mi-512Mi memory)

## Integration Points

### Authentication Flow

Keycloak → Backend JWT validation → Frontend OAuth2 redirect

### Notification Architecture

Backend → Redis queue → Notifications service → SendGrid/Webhooks

### Data Flow

Frontend ↔ Backend API ↔ PostgreSQL (EF Core) ↔ Monitoring (OpenTelemetry)

## Key Files to Reference

- `backend/Program.cs` - API configuration, CORS, JWT, EF setup
- `k8s/deploy.yaml` - Complete infrastructure definition
- `scripts/` - Essential automation (builds, deploys, port forwarding)
  - `reinitialize-minikube.ps1` - Complete fresh setup
  - `deploy-full.ps1` - Deploy with environment sync
  - `forward-all-services.ps1` - Port forwarding for local access
  - `update-env-config.ps1` - Environment configuration management
- `docs/environment-config.md` - Config management guide
- `.github/project-stack-ai.md` - Detailed tech stack rationale

## Common Tasks

**Adding new API endpoint**: Update `backend/Program.cs` minimal API endpoints
**Database changes**: Add/modify models in `backend/Models/`, run EF migrations
**Frontend components**: SvelteKit components in `frontend/src/routes/`
**Monitoring**: Update dashboards in `monitoring/grafana/dashboards/`
**Deploy changes**: Use `scripts/deploy-full.ps1` or VS Code "Deploy Full" task

Do not use emojis in code comments or documentation. Keep comments clear and professional.
