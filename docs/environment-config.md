# Environment Configuration Management

This guide explains how to manage environment variables and configuration for the Perry Chick project using the automated synchronization scripts.

## Overview

The Perry Chick project uses two types of configuration:

- **ConfigMap** (`k8s/configmap.yaml`) - Non-sensitive configuration values
- **Secrets** (`k8s/secrets-generated.yaml`) - Sensitive values like passwords and API keys

Both are automatically generated from your local `.env.local` file using PowerShell scripts.

## Scripts

### 1. `sync-configmap-from-env.ps1`

Synchronizes the Kubernetes ConfigMap with non-sensitive values from `.env.local`.

```powershell
# Generate ConfigMap only
./scripts/sync-configmap-from-env.ps1

# Generate and apply to Kubernetes
./scripts/sync-configmap-from-env.ps1 -Apply

# Create backup before updating
./scripts/sync-configmap-from-env.ps1 -Backup
```

**Excluded from ConfigMap (these go in secrets):**

- `POSTGRES_PASSWORD`
- `KEYCLOAK_ADMIN_PASSWORD`
- `KEYCLOAK_CLIENT_SECRET`
- `KEYCLOAK_DB_PASSWORD`
- `REDIS_PASSWORD`
- `SENDGRID_API_KEY`
- `GRAFANA_ADMIN_PASSWORD`
- `STRAPI_JWT_SECRET`
- `STRAPI_ADMIN_JWT_SECRET`
- `STRAPI_APP_KEYS`
- `STRAPI_API_TOKEN_SALT`
- `DATABASE_URL`

### 2. `update-env-config.ps1`

Complete environment synchronization script that handles both ConfigMap and Secrets.

```powershell
# Generate ConfigMap and Secrets (dry run)
./scripts/update-env-config.ps1

# Generate and apply to Kubernetes
./scripts/update-env-config.ps1 -Apply

# Generate, apply, and restart deployments
./scripts/update-env-config.ps1 -Apply -Restart

# Create backups before updating
./scripts/update-env-config.ps1 -Apply -Restart -Backup
```

## VS Code Tasks

The following tasks are available in VS Code:

| Task                                   | Description                              |
| -------------------------------------- | ---------------------------------------- |
| **Sync ConfigMap from .env**           | Generate ConfigMap from .env.local       |
| **Update Environment Config**          | Generate both ConfigMap and Secrets      |
| **Update Environment Config & Deploy** | Generate, apply, and restart deployments |

Access via: `Ctrl+Shift+P` → `Tasks: Run Task`

## Workflow

### 1. Update Configuration

1. Edit your `.env.local` file with new values
2. Run the sync script:

   ```powershell
   ./scripts/update-env-config.ps1 -Apply -Restart
   ```

### 2. Add New Environment Variables

1. Add the variable to `.env.local`
2. If it's sensitive, add it to the `$sensitiveKeys` array in `sync-configmap-from-env.ps1`
3. Update your application code to use the new variable
4. Update deployment manifests in `k8s/deploy.yaml` if needed
5. Run the sync script to update Kubernetes

### 3. Kubernetes Service URLs

The scripts automatically convert localhost URLs to Kubernetes internal service URLs:

| Local URL                | Kubernetes URL              |
| ------------------------ | --------------------------- |
| `http://localhost:6379`  | `redis:6379`                |
| `http://localhost:8080`  | `http://keycloak:8080`      |
| `http://localhost:9090`  | `http://prometheus:9090`    |
| `http://localhost:3001`  | `http://grafana:3000`       |
| `http://localhost:16686` | `http://jaeger-query:16686` |
| `http://localhost:1337`  | `http://strapi:1337`        |

## Best Practices

### Security

- Never commit `.env.local` to version control
- Use strong, unique passwords for all services
- Rotate sensitive values regularly
- Review the sensitive keys list periodically

### Configuration Management

- Always use the scripts to update configuration
- Test configuration changes in development first
- Create backups when making significant changes
- Verify deployments after configuration updates

### Troubleshooting

#### ConfigMap not updating

```powershell
# Check if ConfigMap was applied
kubectl get configmap perrychick-config -o yaml

# Force restart deployments
kubectl rollout restart deployment/perrychick-backend
kubectl rollout restart deployment/perrychick-frontend
kubectl rollout restart deployment/perrychick-notifications
```

#### Secrets not working

```powershell
# Check if secrets exist
kubectl get secret perrychick-secrets

# Regenerate secrets
./scripts/generate-secrets.ps1
kubectl apply -f k8s/secrets-generated.yaml
```

#### Environment variables not available in pods

```powershell
# Check environment variables in a pod
kubectl exec deployment/perrychick-backend -- env | grep -E "(POSTGRES|REDIS|KEYCLOAK)"

# Check deployment configuration
kubectl describe deployment perrychick-backend
```

## File Structure

```text
scripts/
├── sync-configmap-from-env.ps1     # ConfigMap synchronization
├── update-env-config.ps1           # Complete environment sync
├── generate-secrets.ps1            # Secrets generation
└── ...

k8s/
├── configmap.yaml                  # Generated ConfigMap
├── secrets-generated.yaml         # Generated Secrets (git-ignored)
└── deploy.yaml                     # Main deployment manifests

.env.local                          # Your local environment file (git-ignored)
```

## Example Workflow

```powershell
# 1. Update your environment
vim .env.local

# 2. Sync configuration and deploy
./scripts/update-env-config.ps1 -Apply -Restart

# 3. Verify deployment
kubectl get pods
kubectl logs deployment/perrychick-backend

# 4. Test your application
# Frontend: http://localhost:3000
# Backend API: http://localhost:5000/swagger
```
