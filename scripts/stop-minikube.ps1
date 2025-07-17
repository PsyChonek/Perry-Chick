#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Stops Perry Chick services and cleans up Kubernetes resources
.DESCRIPTION
    Removes all Perry Chick deployments, ConfigMaps, and Secrets from Kubernetes
#>

Write-Host 'Stopping Perry Chick services...' -ForegroundColor Yellow
kubectl delete -f ./k8s/deploy.yaml

Write-Host 'Cleaning up ConfigMaps and Secrets...' -ForegroundColor Yellow
kubectl delete configmap perrychick-config --ignore-not-found=true
kubectl delete secret perrychick-secrets --ignore-not-found=true

Write-Host 'All services stopped and cleaned up!' -ForegroundColor Green
