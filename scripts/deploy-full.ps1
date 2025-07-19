#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploys Perry Chick with full environment synchronization
.DESCRIPTION
    Synchronizes environment configuration, deploys application, and creates dashboards.
    Requires Minikube to be running.
#>

Write-Host 'Starting full deployment with environment synchronization...' -ForegroundColor Green

# Check if Minikube is running
try {
	kubectl cluster-info | Out-Null
	Write-Host '✅ Kubernetes cluster is accessible' -ForegroundColor Green
}
catch {
	Write-Error '❌ Kubernetes cluster not accessible. Please run: ./scripts/minikube.ps1'
	exit 1
}

Write-Host 'Step 1: Synchronizing environment configuration...' -ForegroundColor Yellow
./scripts/update-env-config.ps1 -Apply

Write-Host 'Step 2: Deploying application...' -ForegroundColor Yellow
kubectl apply -f ./k8s/deploy.yaml

Write-Host 'Step 3: Setting up dashboards...' -ForegroundColor Yellow
./scripts/grafana-dashboards.ps1

Write-Host 'Step 4: Restarting deployments to pick up changes...' -ForegroundColor Yellow
kubectl rollout restart deployment/perrychick-backend deployment/perrychick-frontend deployment/perrychick-notifications

Write-Host 'Full deployment complete! ✅' -ForegroundColor Green
