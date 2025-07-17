#!/usr/bin/env pwsh
# Script to generate Kubernetes secrets from .env.local file
# Usage: .\generate-secrets.ps1

param(
    [string]$EnvFile = ".env.local",
    [string]$SecretName = "perrychick-secrets",
    [string]$OutputFile = "k8s/secrets-generated.yaml"
)

Write-Host "🔐 Generating Kubernetes secrets from $EnvFile..." -ForegroundColor Green

if (!(Test-Path $EnvFile)) {
    Write-Host "❌ Error: $EnvFile not found!" -ForegroundColor Red
    Write-Host "Please ensure you have a $EnvFile file in the root directory." -ForegroundColor Yellow
    exit 1
}

# Read the .env file and extract sensitive variables
$envContent = Get-Content $EnvFile
$secrets = @{}

# Define which variables should be treated as secrets
$secretKeys = @(
    "POSTGRES_PASSWORD",
    "KEYCLOAK_ADMIN_PASSWORD",
    "KEYCLOAK_DB_PASSWORD",
    "REDIS_PASSWORD",
    "SENDGRID_API_KEY",
    "DATABASE_URL",
    "KEYCLOAK_CLIENT_SECRET",
    "STRAPI_JWT_SECRET",
    "STRAPI_ADMIN_JWT_SECRET",
    "STRAPI_APP_KEYS",
    "STRAPI_API_TOKEN_SALT",
    "STRAPI_API_TOKEN",
    "STRAPI_TRANSFER_TOKEN_SALT",
    "GRAFANA_ADMIN_PASSWORD"
)

foreach ($line in $envContent) {
    if ($line -match "^([^#][^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()

        # Remove quotes if present
        $value = $value -replace '^"(.*)"$', '$1'
        $value = $value -replace "^'(.*)'$", '$1'

        if ($secretKeys -contains $key -and $value -ne "" -and $value -ne "your_*_here") {
            # Convert to base64
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($value)
            $base64 = [System.Convert]::ToBase64String($bytes)
            $secrets[$key] = $base64
            Write-Host "  ✓ Added secret: $key" -ForegroundColor Cyan
        }
    }
}

# Generate the secrets YAML
$yaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: $SecretName
type: Opaque
data:
"@

foreach ($key in $secrets.Keys | Sort-Object) {
    $yaml += "`n  $key`: $($secrets[$key])"
}

# Ensure the k8s directory exists
if (!(Test-Path "k8s")) {
    New-Item -ItemType Directory -Path "k8s" | Out-Null
}

# Write the secrets file
$yaml | Out-File -FilePath $OutputFile -Encoding utf8
Write-Host "✅ Secrets generated successfully: $OutputFile" -ForegroundColor Green
