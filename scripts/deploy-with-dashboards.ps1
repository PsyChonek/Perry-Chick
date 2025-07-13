#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploys Perry Chick application with Grafana dashboards from separate files
.DESCRIPTION
    This script creates Kubernetes ConfigMaps for Grafana dashboards by reading
    separate JSON files, then deploys the full application stack.
.PARAMETER GenerateSecrets
    Generate secrets before deployment
#>

param(
    [switch]$GenerateSecrets
)

Write-Host "🚀 Deploying Perry Chick with Grafana Dashboards..." -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "k8s/deploy.yaml")) {
    Write-Error "Please run this script from the project root directory"
    exit 1
}

# Generate secrets if requested
if ($GenerateSecrets) {
    Write-Host "📋 Generating secrets..." -ForegroundColor Yellow
    if (Test-Path "scripts/generate-secrets.ps1") {
        & "./scripts/generate-secrets.ps1"
    } else {
        Write-Warning "generate-secrets.ps1 not found, skipping secret generation"
    }
}

# Create temporary directory for generated manifests
$tempDir = "temp-k8s"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    Write-Host "📊 Creating Grafana dashboard ConfigMaps..." -ForegroundColor Yellow

    # Check if dashboard files exist
    $dashboardFiles = @(
        "monitoring/grafana/dashboards/perry-chick-overview.json",
        "monitoring/grafana/dashboards/perry-chick-database.json",
        "monitoring/grafana/dashboards/perry-chick-business.json",
        "monitoring/grafana/dashboards/perry-chick-notifications.json"
    )

    $missingFiles = @()
    foreach ($file in $dashboardFiles) {
        if (-not (Test-Path $file)) {
            $missingFiles += $file
        }
    }

    if ($missingFiles.Count -gt 0) {
        Write-Warning "Some dashboard files are missing:"
        $missingFiles | ForEach-Object { Write-Warning "  - $_" }
        Write-Host "Continuing with available dashboards..." -ForegroundColor Yellow
    }

    # Create ConfigMap YAML for dashboards
    $configMapYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
data:
"@

    foreach ($file in $dashboardFiles) {
        if (Test-Path $file) {
            $dashboardName = Split-Path $file -Leaf
            $dashboardContent = Get-Content $file -Raw

            # Indent the JSON content properly for YAML
            $indentedContent = $dashboardContent -split "`n" | ForEach-Object {
                if ($_ -ne "") {
                    "    $_"
                } else {
                    ""
                }
            }

            $configMapYaml += "`n  $dashboardName`: |"
            $configMapYaml += "`n" + ($indentedContent -join "`n")
        }
    }

    # Save the ConfigMap to temporary file
    $configMapYaml | Out-File -FilePath "$tempDir/grafana-dashboards.yaml" -Encoding UTF8

    Write-Host "✅ Dashboard ConfigMap created" -ForegroundColor Green

    # Apply the ConfigMaps first
    Write-Host "📦 Applying ConfigMaps..." -ForegroundColor Yellow
    kubectl apply -f "k8s/configmap.yaml" 2>$null
    kubectl apply -f "$tempDir/grafana-dashboards.yaml"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to apply dashboard ConfigMaps"
        exit 1
    }

    # Apply secrets
    Write-Host "🔐 Applying secrets..." -ForegroundColor Yellow
    kubectl apply -f "k8s/secrets-generated.yaml"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to apply secrets"
        exit 1
    }

    # Apply main deployment (without the embedded dashboard ConfigMap)
    Write-Host "🚢 Deploying main application..." -ForegroundColor Yellow
    kubectl apply -f "k8s/deploy.yaml"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy main application"
        exit 1
    }

    Write-Host "" -ForegroundColor Green
    Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "📊 Grafana dashboards loaded from separate files:" -ForegroundColor Cyan
    foreach ($file in $dashboardFiles) {
        if (Test-Path $file) {
            $dashboardName = Split-Path $file -Leaf
            Write-Host "  ✅ $dashboardName" -ForegroundColor Green
        } else {
            $dashboardName = Split-Path $file -Leaf
            Write-Host "  ❌ $dashboardName (file not found)" -ForegroundColor Red
        }
    }
    Write-Host "" -ForegroundColor Green
    Write-Host "🔗 Access your services:" -ForegroundColor Cyan
    Write-Host "  - Frontend:      http://localhost:3000" -ForegroundColor White
    Write-Host "  - Backend API:   http://localhost:5000" -ForegroundColor White
    Write-Host "  - Grafana:       http://localhost:3001" -ForegroundColor White
    Write-Host "  - Prometheus:    http://localhost:9090" -ForegroundColor White
    Write-Host "  - Jaeger:        http://localhost:16686" -ForegroundColor White
    Write-Host "" -ForegroundColor Green
    Write-Host "💡 To start port forwarding, run:" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/grafana 3001:3000" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Green

} finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
}
