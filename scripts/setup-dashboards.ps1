#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates and deploys Grafana dashboard configurations
.DESCRIPTION
    Creates a Kubernetes ConfigMap for Grafana dashboards from JSON files
    and applies the deployment configuration.
#>

Write-Host "📊 Setting up Grafana Dashboards..." -ForegroundColor Green

# Check if Kubernetes cluster is accessible
try {
	kubectl cluster-info | Out-Null
}
catch {
	Write-Error "❌ Kubernetes cluster not accessible. Please run: ./scripts/reinitialize-minikube.ps1"
	exit 1
}

# Check if we're in the right directory
if (-not (Test-Path "monitoring/grafana/dashboards")) {
	Write-Error "Please run this script from the project root directory"
	Write-Error "Expected directory: monitoring/grafana/dashboards/"
	exit 1
}

# Find all JSON dashboard files
$dashboardFiles = Get-ChildItem -Path "monitoring/grafana/dashboards/" -Filter "*.json"

if ($dashboardFiles.Count -eq 0) {
	Write-Warning "No dashboard JSON files found in monitoring/grafana/dashboards/"
	exit 1
}

Write-Host "Found $($dashboardFiles.Count) dashboard files" -ForegroundColor Cyan

# Create ConfigMap
Write-Host "Creating ConfigMap 'grafana-dashboards'..." -ForegroundColor Yellow

try {
	# Delete existing ConfigMap if it exists
	kubectl delete configmap grafana-dashboards 2>$null | Out-Null

	# Create new ConfigMap from files
	$kubectlArgs = @("create", "configmap", "grafana-dashboards")
	foreach ($file in $dashboardFiles) {
		$kubectlArgs += "--from-file=$($file.FullName)"
	}

	& kubectl $kubectlArgs

	if ($LASTEXITCODE -eq 0) {
		Write-Host "✅ ConfigMap created successfully!" -ForegroundColor Green

		# Apply deployment to pick up dashboard changes
		Write-Host "Applying deployment configuration..." -ForegroundColor Yellow
		kubectl apply -f k8s/deploy.yaml

		Write-Host "✅ Dashboard setup complete!" -ForegroundColor Green
	}
 else {
		Write-Error "Failed to create ConfigMap"
		exit 1
	}
}
catch {
	Write-Error "Error creating dashboard ConfigMap: $($_.Exception.Message)"
	exit 1
}
