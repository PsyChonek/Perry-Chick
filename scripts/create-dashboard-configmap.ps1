#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates Grafana dashboard ConfigMap from separate JSON files
.DESCRIPTION
    This script creates a Kubernetes ConfigMap for Grafana dashboards by reading
    individual JSON files from the monitoring/grafana/dashboards/ directory.
#>

Write-Host "📊 Creating Grafana Dashboard ConfigMap..." -ForegroundColor Green

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

Write-Host "Found $($dashboardFiles.Count) dashboard files:" -ForegroundColor Cyan
$dashboardFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }

# Create the ConfigMap using kubectl
Write-Host "`nCreating ConfigMap 'grafana-dashboards'..." -ForegroundColor Yellow

try {
    # Delete existing ConfigMap if it exists (ignore errors)
    kubectl delete configmap grafana-dashboards 2>$null | Out-Null

    # Create new ConfigMap from files
    $args = @("create", "configmap", "grafana-dashboards")
    foreach ($file in $dashboardFiles) {
        $args += "--from-file=$($file.FullName)"
    }

    & kubectl $args

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ConfigMap 'grafana-dashboards' created successfully!" -ForegroundColor Green
        Write-Host "`nDashboards included:" -ForegroundColor Cyan
        $dashboardFiles | ForEach-Object {
            Write-Host "  ✅ $($_.BaseName)" -ForegroundColor Green
        }
        Write-Host "`n💡 Tip: Grafana will automatically load these dashboards in the 'Perry Chick' folder" -ForegroundColor Yellow
    } else {
        Write-Error "Failed to create ConfigMap"
        exit 1
    }
} catch {
    Write-Error "Error creating ConfigMap: $($_.Exception.Message)"
    exit 1
}
