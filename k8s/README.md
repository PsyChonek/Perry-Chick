# Perry Chick Kubernetes Deployment with Environment Variables

This directory contains Kubernetes manifests for deploying Perry Chick using ConfigMaps and Secrets for environment variable management.

## 📁 Files Overview

- `configmap.yaml` - Non-sensitive configuration data
- `secrets.yaml` - Template for sensitive data (passwords, API keys)
- `deploy.yaml` - Main deployment manifests using ConfigMaps and Secrets
- `secrets-generated.yaml` - Auto-generated secrets from your `.env.local` file (git-ignored)

## 🚀 Quick Start

### 1. Generate Secrets from Environment File

```powershell
# Generate secrets from your .env.local file
.\scripts\generate-secrets.ps1

# Or during deployment
.\scripts\deploy-with-env.ps1 -GenerateSecrets
```

### 2. Deploy Everything

```powershell
# Deploy with environment variables
.\scripts\deploy-with-env.ps1 -GenerateSecrets

# Or deploy without rebuilding images
.\scripts\deploy-with-env.ps1 -GenerateSecrets -SkipBuild
```

### 3. Manual Deployment

```powershell
# Apply manifests in order
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets-generated.yaml  # or k8s/secrets.yaml
kubectl apply -f k8s/deploy.yaml
```

## 🔧 Configuration Management

### ConfigMap (Non-sensitive data)

Located in `configmap.yaml`, contains:

- Database names and connection strings (without passwords)
- Application URLs
- Service discovery endpoints
- Public configuration

### Secrets (Sensitive data)

- **Template**: `secrets.yaml` (base64 encoded placeholders)
- **Generated**: `secrets-generated.yaml` (auto-generated from `.env.local`)

Contains:

- Database passwords
- API keys
- Authentication tokens
- Connection strings with credentials

## 📝 Environment Variables Mapping

### Database Configuration

| Environment Variable | Source    | Description            |
| -------------------- | --------- | ---------------------- |
| `POSTGRES_DB`        | ConfigMap | Database name          |
| `POSTGRES_USER`      | ConfigMap | Database username      |
| `POSTGRES_PASSWORD`  | Secret    | Database password      |
| `DATABASE_URL`       | Secret    | Full connection string |

### Authentication (Keycloak)

| Environment Variable      | Source    | Description       |
| ------------------------- | --------- | ----------------- |
| `KEYCLOAK_ADMIN`          | ConfigMap | Admin username    |
| `KEYCLOAK_ADMIN_PASSWORD` | Secret    | Admin password    |
| `KEYCLOAK_URL`            | ConfigMap | Service URL       |
| `KEYCLOAK_REALM`          | ConfigMap | Realm name        |
| `KEYCLOAK_CLIENT_ID`      | ConfigMap | Client identifier |

### Cache (Redis)

| Environment Variable | Source    | Description          |
| -------------------- | --------- | -------------------- |
| `REDIS_URL`          | ConfigMap | Redis connection URL |
| `REDIS_PASSWORD`     | Secret    | Redis password       |

### Notifications

| Environment Variable | Source    | Description          |
| -------------------- | --------- | -------------------- |
| `SENDGRID_API_KEY`   | Secret    | SendGrid API key     |
| `FROM_EMAIL`         | ConfigMap | Default sender email |

## 🔒 Security Best Practices

### 1. Secrets Management

- Never commit `secrets-generated.yaml` to version control
- Use strong, unique passwords in your `.env.local` file
- Rotate secrets regularly
- Use external secret management in production (e.g., Azure Key Vault, AWS Secrets Manager)

### 2. Environment Files

```bash
# Good - separate environment files
.env.local          # Local development
.env.staging        # Staging environment
.env.production     # Production environment (never committed)
```

### 3. Base64 Encoding

Kubernetes secrets require base64 encoding. The generation script handles this automatically:

```powershell
# Manual encoding if needed
$text = "your-secret-value"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
$base64 = [System.Convert]::ToBase64String($bytes)
```

## 🛠️ Customization

### Adding New Environment Variables

1. **Non-sensitive data** → Add to `configmap.yaml`
2. **Sensitive data** → Add to `secrets.yaml` and update generation script
3. **Application code** → Reference in deployment manifests

### Example: Adding a new configuration

```yaml
# In configmap.yaml
data:
  NEW_CONFIG_VALUE: "some-value"

# In deployment
env:
  - name: NEW_CONFIG_VALUE
    valueFrom:
      configMapKeyRef:
        name: perrychick-config
        key: NEW_CONFIG_VALUE
```

### Example: Adding a new secret

```yaml
# In secrets.yaml (base64 encoded)
data:
  NEW_SECRET_VALUE: <base64-encoded-value>

# In deployment
env:
  - name: NEW_SECRET_VALUE
    valueFrom:
      secretKeyRef:
        name: perrychick-secrets
        key: NEW_SECRET_VALUE
```

## 🐛 Troubleshooting

### Check Configuration

```powershell
# View ConfigMap
kubectl get configmap perrychick-config -o yaml

# View Secrets (base64 encoded)
kubectl get secret perrychick-secrets -o yaml

# Decode a secret value
kubectl get secret perrychick-secrets -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

### Check Environment Variables in Pods

```powershell
# List environment variables in a pod
kubectl exec deployment/perrychick-backend -- env | grep -E "(POSTGRES|REDIS|KEYCLOAK)"

# Check specific variable
kubectl exec deployment/perrychick-backend -- printenv DATABASE_URL
```

### Common Issues

1. **Pod fails to start**: Check if ConfigMap and Secrets exist
2. **Missing environment variables**: Verify ConfigMap/Secret references
3. **Base64 encoding errors**: Use the generation script or verify manual encoding
4. **Service connection issues**: Check internal DNS names in ConfigMap

## 📚 Additional Resources

- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Environment Variables in Kubernetes](https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/)
