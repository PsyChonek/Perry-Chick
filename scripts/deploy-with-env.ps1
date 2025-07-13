#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploys Perry Chick application with environment variables and secrets
.DESCRIPTION
    This script generates secrets from .env.local, creates ConfigMaps,
    and deploys the full Perry Chick application stack to Kubernetes.
.PARAMETER GenerateSecrets
    Generate secrets before deployment
.PARAMETER CreateEnvFile
    Create .env.local from .env.example if it doesn't exist
.PARAMETER BuildImages
    Build Docker images for Perry Chick services before deployment
#>

param(
    [switch]$GenerateSecrets,
    [switch]$CreateEnvFile,
    [switch]$BuildImages
)

Write-Host "🚀 Deploying Perry Chick with Environment Configuration..." -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "k8s/deploy.yaml")) {
    Write-Error "Please run this script from the project root directory"
    exit 1
}

# Create .env.local from .env.example if it doesn't exist and CreateEnvFile is specified
if ($CreateEnvFile -and -not (Test-Path ".env.local")) {
    Write-Host "📋 Creating .env.local from .env.example..." -ForegroundColor Yellow
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env.local"
        Write-Host "✅ .env.local created. Please edit it with your actual values." -ForegroundColor Green
    } else {
        Write-Error ".env.example not found!"
        exit 1
    }
}

# Check if .env.local exists
if (-not (Test-Path ".env.local")) {
    Write-Host "❌ .env.local file not found!" -ForegroundColor Red
    Write-Host "Please create .env.local from .env.example and configure your values." -ForegroundColor Yellow
    Write-Host "You can run: ./scripts/deploy-with-env.ps1 -CreateEnvFile -GenerateSecrets" -ForegroundColor Cyan
    exit 1
}

# Generate secrets if requested or if secrets file doesn't exist
if ($GenerateSecrets -or -not (Test-Path "k8s/secrets-generated.yaml")) {
    Write-Host "🔐 Generating secrets from .env.local..." -ForegroundColor Yellow
    if (Test-Path "scripts/generate-secrets.ps1") {
        & "./scripts/generate-secrets.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to generate secrets"
            exit 1
        }
    } else {
        Write-Error "generate-secrets.ps1 not found!"
        exit 1
    }
}

# Build Docker images if requested
if ($BuildImages) {
    Write-Host "🐳 Building Docker images..." -ForegroundColor Yellow
    if (Test-Path "scripts/build-images.ps1") {
        & "./scripts/build-images.ps1" -UseMinikube
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to build Docker images"
            exit 1
        }
    } else {
        Write-Error "build-images.ps1 not found!"
        exit 1
    }
}

# Apply ConfigMap first
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
} else {
    Write-Warning "secrets-generated.yaml not found, some services may fail to start"
}

# Apply main deployment
Write-Host "🚀 Deploying Perry Chick application..." -ForegroundColor Yellow
kubectl apply -f k8s/deploy.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to apply deployment"
    exit 1
}

# Wait a moment for pods to start
Write-Host "⏳ Waiting for pods to start..." -ForegroundColor Yellow
Start-Sleep 5

# Check pod status
Write-Host "📊 Checking pod status..." -ForegroundColor Yellow
kubectl get pods -o wide

Write-Host ""
Write-Host "✅ Perry Chick deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 To access the services, run the port forwarding task:" -ForegroundColor Cyan
Write-Host "   kubectl port-forward service/perrychick-frontend 3000:3000" -ForegroundColor White
Write-Host "   kubectl port-forward service/perrychick-backend 5000:5000" -ForegroundColor White
Write-Host "   kubectl port-forward service/keycloak 8080:8080" -ForegroundColor White
Write-Host ""
Write-Host "📋 Or use the VS Code task: 'Forward All Services & Show URLs'" -ForegroundColor Cyan
