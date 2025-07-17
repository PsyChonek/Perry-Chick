#!/usr/bin/env pwsh

<#
.SYNOPSI# Define sensitive variables that should go to secrets instead of ConfigMap
$sensitiveVars = @(
    "POSTGRES_PASSWORD",
    "DATABASE_URL",
    "KEYCLOAK_ADMIN_PASSWORD",
    "KEYCLOAK_CLIENT_SECRET",
    "KEYCLOAK_DB_PASSWORD",
    "REDIS_PASSWORD",
    "SENDGRID_API_KEY",
    "GRAFANA_ADMIN_PASSWORD",
    "STRAPI_JWT_SECRET",
    "STRAPI_ADMIN_JWT_SECRET",
    "STRAPI_APP_KEYS",
    "STRAPI_API_TOKEN_SALT",
    "STRAPI_API_TOKEN",
    "STRAPI_TRANSFER_TOKEN_SALT"
)environment synchronization and deployment script
.DESCRIPTION
    This script synchronizes both ConfigMap and Secrets from .env.local,
    then optionally deploys the updated configuration to Kubernetes.
.PARAMETER Apply
    Apply changes to Kubernetes cluster
.PARAMETER Restart
    Restart deployments after applying changes
.PARAMETER Backup
    Create backups before updating
#>

param(
	[switch]$Apply,
	[switch]$Restart,
	[switch]$Backup
)

Write-Host "🚀 Perry Chick Environment Synchronization" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Ensure we're in the project root
if (-not (Test-Path ".env.local")) {
	Write-Error "Please run this script from the project root directory where .env.local exists"
	exit 1
}

# Step 1: Sync ConfigMap
Write-Host ""
Write-Host "📋 Step 1: Synchronizing ConfigMap from .env.local..." -ForegroundColor Cyan

# Define sensitive variables that should go to secrets instead of ConfigMap
$sensitiveVars = @(
	"POSTGRES_PASSWORD",
	"DATABASE_URL",
	"KEYCLOAK_ADMIN_PASSWORD",
	"KEYCLOAK_CLIENT_SECRET",
	"KEYCLOAK_DB_PASSWORD",
	"REDIS_PASSWORD",
	"SENDGRID_API_KEY",
	"GRAFANA_ADMIN_PASSWORD",
	"STRAPI_JWT_SECRET",
	"STRAPI_ADMIN_JWT_SECRET",
	"STRAPI_APP_KEYS",
	"STRAPI_API_TOKEN_SALT",
	"STRAPI_API_TOKEN",
	"STRAPI_TRANSFER_TOKEN_SALT"
)

# Read .env.local and filter out sensitive values and comments
$envContent = Get-Content .env.local | Where-Object {
	$_ -match "^[A-Z_]+=.+" -and
	-not ($sensitiveVars -contains $_.Split('=')[0])
}

# Create ConfigMap YAML
$configMapContent = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: perrychick-config
data:
"@

foreach ($line in $envContent) {
	if ($line -match "^([A-Z_]+)=(.*)$") {
		$key = $matches[1]
		$value = $matches[2]
		# Remove quotes if present
		$value = $value -replace '^"(.*)"$', '$1'
		$configMapContent += "`n  $key`: `"$value`""
	}
}

# Write ConfigMap to file
$configMapContent | Out-File -FilePath "k8s/configmap.yaml" -Encoding UTF8
Write-Host "✅ ConfigMap synchronized from .env.local" -ForegroundColor Green

# Step 2: Generate Secrets
Write-Host ""
Write-Host "🔐 Step 2: Generating Secrets from .env.local..." -ForegroundColor Cyan
if (Test-Path "scripts/generate-secrets.ps1") {
	& "./scripts/generate-secrets.ps1"
	if ($LASTEXITCODE -ne 0) {
		Write-Error "Failed to generate secrets"
		exit 1
	}
}
else {
	Write-Warning "generate-secrets.ps1 not found, skipping secret generation"
}

# Step 3: Apply to Kubernetes if requested
if ($Apply) {
	Write-Host ""
	Write-Host "🚀 Step 3: Applying configuration to Kubernetes..." -ForegroundColor Cyan

	# Apply ConfigMap
	Write-Host "📋 Applying ConfigMap..." -ForegroundColor Yellow
	kubectl apply -f k8s/configmap.yaml
	if ($LASTEXITCODE -ne 0) {
		Write-Error "Failed to apply ConfigMap"
		exit 1
	}

	# Apply Secrets
	Write-Host "🔐 Applying Secrets..." -ForegroundColor Yellow
	if (Test-Path "k8s/secrets-generated.yaml") {
		kubectl apply -f k8s/secrets-generated.yaml
		if ($LASTEXITCODE -ne 0) {
			Write-Error "Failed to apply secrets"
			exit 1
		}
	}
 else {
		Write-Warning "secrets-generated.yaml not found, skipping secrets application"
	}

	Write-Host "✅ Configuration applied successfully" -ForegroundColor Green
}

# Step 4: Restart deployments if requested
if ($Restart -and $Apply) {
	Write-Host ""
	Write-Host "🔄 Step 4: Restarting deployments..." -ForegroundColor Cyan

	$deployments = @(
		"perrychick-backend",
		"perrychick-frontend",
		"perrychick-notifications"
	)

	foreach ($deployment in $deployments) {
		Write-Host "🔄 Restarting $deployment..." -ForegroundColor Yellow
		kubectl rollout restart deployment/$deployment
		if ($LASTEXITCODE -eq 0) {
			Write-Host "✅ $deployment restarted" -ForegroundColor Green
		}
		else {
			Write-Warning "Failed to restart $deployment"
		}
	}

	Write-Host ""
	Write-Host "⏳ Waiting for deployments to complete..." -ForegroundColor Yellow
	foreach ($deployment in $deployments) {
		kubectl rollout status deployment/$deployment --timeout=300s
	}
}

Write-Host ""
Write-Host "🎉 Environment synchronization complete!" -ForegroundColor Green
Write-Host ""

if (-not $Apply) {
	Write-Host "💡 To apply changes to Kubernetes, run:" -ForegroundColor Cyan
	Write-Host "   ./scripts/update-env-config.ps1 -Apply -Restart" -ForegroundColor White
}

Write-Host ""
Write-Host "📊 Configuration Status:" -ForegroundColor Cyan
Write-Host "  ✅ ConfigMap: k8s/configmap.yaml" -ForegroundColor Green
if (Test-Path "k8s/secrets-generated.yaml") {
	Write-Host "  ✅ Secrets: k8s/secrets-generated.yaml" -ForegroundColor Green
}
else {
	Write-Host "  ⚠️  Secrets: not generated" -ForegroundColor Yellow
}

if ($Apply) {
	Write-Host "  ✅ Applied to Kubernetes" -ForegroundColor Green
	if ($Restart) {
		Write-Host "  ✅ Deployments restarted" -ForegroundColor Green
	}
}
