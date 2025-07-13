#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy Perry Chick Grafana dashboards
.DESCRIPTION
    This script updates the Kubernetes deployment with the latest Grafana dashboard configurations.
.EXAMPLE
    .\deploy-dashboards.ps1
#>

Write-Host "🎯 Deploying Perry Chick Grafana Dashboards..." -ForegroundColor Green

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed or not in PATH"
    exit 1
}

# Check if we're connected to a cluster
try {
    kubectl cluster-info | Out-Null
    Write-Host "✅ Connected to Kubernetes cluster" -ForegroundColor Green
} catch {
    Write-Error "Not connected to a Kubernetes cluster. Please configure kubectl."
    exit 1
}

# Apply the updated deployment with dashboard configurations
Write-Host "📊 Applying Grafana dashboard configurations..." -ForegroundColor Yellow
kubectl apply -f k8s/deploy.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dashboard configurations applied successfully!" -ForegroundColor Green

    # Check if Grafana pod is running
    Write-Host "🔍 Checking Grafana pod status..." -ForegroundColor Yellow
    $grafanaPod = kubectl get pods -l app=grafana --no-headers -o custom-columns=":metadata.name"

    if ($grafanaPod) {
        Write-Host "📦 Grafana pod: $grafanaPod" -ForegroundColor Cyan

        # Wait a moment for the pod to restart if needed
        Start-Sleep 5

        # Check pod status
        $podStatus = kubectl get pod $grafanaPod --no-headers -o custom-columns=":status.phase"
        if ($podStatus -eq "Running") {
            Write-Host "✅ Grafana is running!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Grafana pod status: $podStatus" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "🌐 Access Information:" -ForegroundColor White
        Write-Host "  To access Grafana dashboards:" -ForegroundColor Cyan
        Write-Host "  1. Port forward: kubectl port-forward service/grafana 3001:3000" -ForegroundColor Cyan
        Write-Host "  2. Open browser: http://localhost:3001" -ForegroundColor Cyan
        Write-Host "  3. Login: admin / adminpassword" -ForegroundColor Cyan
        Write-Host "  4. Navigate to 'Perry Chick' folder in dashboards" -ForegroundColor Cyan

        Write-Host ""
        Write-Host "📊 Available Dashboards:" -ForegroundColor White
        Write-Host "  • Perry Chick - Overview" -ForegroundColor Green
        Write-Host "  • Perry Chick - Database Monitoring" -ForegroundColor Green
        Write-Host "  • Perry Chick - Business Metrics" -ForegroundColor Green
        Write-Host "  • Perry Chick - Notifications & Redis" -ForegroundColor Green

    } else {
        Write-Warning "Grafana pod not found. The deployment might still be starting."
    }
} else {
    Write-Error "Failed to apply dashboard configurations"
    exit 1
}

Write-Host ""
Write-Host "🎉 Dashboard deployment complete!" -ForegroundColor Green
