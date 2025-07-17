#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Reinitializes Minikube with full Perry Chick deployment
.DESCRIPTION
    Stops existing Minikube, starts fresh with network configuration, builds images,
    deploys services, and sets up monitoring dashboards.
#>

Write-Host 'Starting full Minikube deployment with environment variables, builds, and dashboards...' -ForegroundColor Green

Write-Host 'Step 1: Stopping any existing Minikube...' -ForegroundColor Yellow
minikube delete 2>$null

Write-Host 'Step 2: Starting Minikube with network fixes...' -ForegroundColor Yellow
minikube start --driver=docker --dns-domain=cluster.local --extra-config=kubelet.cluster-dns=10.96.0.10 --extra-config=kubelet.cluster-domain=cluster.local --memory=4096 --cpus=2

Write-Host 'Step 3: Building Docker images...' -ForegroundColor Yellow
./scripts/build-images.ps1 -UseMinikube

Write-Host 'Step 4: Deploying application with environment sync...' -ForegroundColor Yellow
./scripts/deploy-full.ps1

Write-Host 'Full deployment complete! 🎉' -ForegroundColor Green
