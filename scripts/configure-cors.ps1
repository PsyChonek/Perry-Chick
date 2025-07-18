#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Configures CORS settings across all Perry Chick services
.DESCRIPTION
    This script ensures CORS configuration is properly set up across:
    - Backend deployment in Kubernetes
    - Keycloak deployment in Kubernetes
    - Local development environment (.env.local)
    - ConfigMap for environment variables
.PARAMETER Apply
    Apply changes to Kubernetes cluster
.PARAMETER UpdateEnv
    Update .env.local with CORS configuration
#>

param(
    [switch]$Apply,
    [switch]$UpdateEnv
)

Write-Host "🌐 Perry Chick CORS Configuration" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# CORS configuration values
$corsConfig = @{
    "CORS_ALLOWED_ORIGINS" = "http://localhost:3000,http://localhost:5173,https://localhost:3000,https://localhost:5173"
    "CORS_ALLOWED_METHODS" = "GET,POST,PUT,DELETE,OPTIONS,PATCH"
    "CORS_ALLOWED_HEADERS" = "Authorization,Content-Type,Accept,Origin,User-Agent,Cache-Control"
    "KC_HTTP_CORS_ENABLED" = "true"
    "KC_HTTP_CORS_ORIGINS" = "http://localhost:3000,http://localhost:5173,https://localhost:3000,https://localhost:5173"
}

# Function to update .env.local
function Update-EnvLocal {
    Write-Host "📝 Updating .env.local with CORS configuration..." -ForegroundColor Yellow

    if (-not (Test-Path ".env.local")) {
        Write-Error ".env.local file not found. Please run from project root directory."
        return $false
    }

    $envContent = Get-Content ".env.local" -Raw
    $envLines = Get-Content ".env.local"
    $updated = $false

    # Check if CORS section already exists
    if ($envContent -notmatch "# CORS Configuration") {
        Write-Host "  Adding CORS configuration section..." -ForegroundColor Cyan

        # Add CORS section to .env.local
        $corsSection = @"

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173,https://localhost:3000,https://localhost:5173
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS,PATCH
CORS_ALLOWED_HEADERS=Authorization,Content-Type,Accept,Origin,User-Agent,Cache-Control

# Keycloak CORS Configuration
KC_HTTP_CORS_ENABLED=true
KC_HTTP_CORS_ORIGINS=http://localhost:3000,http://localhost:5173,https://localhost:3000,https://localhost:5173
"@

        Add-Content -Path ".env.local" -Value $corsSection
        $updated = $true
    } else {
        Write-Host "  CORS section already exists, updating values..." -ForegroundColor Cyan

        # Update existing values
        foreach ($key in $corsConfig.Keys) {
            $value = $corsConfig[$key]
            $pattern = "^$key\s*=.*$"
            $replacement = "$key=$value"

            if ($envContent -match $pattern) {
                $envContent = $envContent -replace $pattern, $replacement
                $updated = $true
            } else {
                # Add missing CORS variable
                $envContent += "`n$replacement"
                $updated = $true
            }
        }

        if ($updated) {
            $envContent | Set-Content ".env.local"
        }
    }

    if ($updated) {
        Write-Host "  ✅ .env.local updated with CORS configuration" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  .env.local already has correct CORS configuration" -ForegroundColor Cyan
    }

    return $true
}

# Function to update ConfigMap
function Update-ConfigMap {
    Write-Host "📋 Updating ConfigMap with CORS configuration..." -ForegroundColor Yellow

    if (-not (Test-Path "k8s/configmap.yaml")) {
        Write-Warning "ConfigMap not found. Run update-env-config.ps1 first."
        return $false
    }

    $configContent = Get-Content "k8s/configmap.yaml" -Raw
    $updated = $false

    foreach ($key in $corsConfig.Keys) {
        $value = $corsConfig[$key]
        $pattern = "^\s*$key\s*:.*$"
        $replacement = "  $key`: `"$value`""

        if ($configContent -match $pattern) {
            $configContent = $configContent -replace $pattern, $replacement
            $updated = $true
        } else {
            # Add missing CORS variable to ConfigMap
            $dataSection = $configContent -replace "(data:\s*)", "`$1`n  $key`: `"$value`""
            $configContent = $dataSection
            $updated = $true
        }
    }

    if ($updated) {
        $configContent | Set-Content "k8s/configmap.yaml"
        Write-Host "  ✅ ConfigMap updated with CORS configuration" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  ConfigMap already has correct CORS configuration" -ForegroundColor Cyan
    }

    return $true
}

# Function to apply Kubernetes changes
function Apply-KubernetesChanges {
    Write-Host "🔄 Applying CORS configuration to Kubernetes..." -ForegroundColor Yellow

    try {
        # Apply ConfigMap changes
        kubectl apply -f k8s/configmap.yaml
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to apply ConfigMap changes"
            return $false
        }

        Write-Host "  ✅ ConfigMap applied successfully" -ForegroundColor Green

        # Restart deployments to pick up new environment variables
        $deployments = @(
            "perrychick-backend",
            "keycloak"
        )

        foreach ($deployment in $deployments) {
            Write-Host "  🔄 Restarting $deployment..." -ForegroundColor Cyan
            kubectl rollout restart deployment/$deployment
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✅ $deployment restarted" -ForegroundColor Green
            } else {
                Write-Warning "    Failed to restart $deployment"
            }
        }

        # Wait for deployments to be ready
        Write-Host "  ⏳ Waiting for deployments to complete..." -ForegroundColor Cyan
        foreach ($deployment in $deployments) {
            kubectl rollout status deployment/$deployment --timeout=300s
        }

        return $true
    }
    catch {
        Write-Error "Failed to apply Kubernetes changes: $_"
        return $false
    }
}

# Main execution
try {
    # Update .env.local if requested
    if ($UpdateEnv) {
        if (-not (Update-EnvLocal)) {
            exit 1
        }
    }

    # Update ConfigMap
    if (-not (Update-ConfigMap)) {
        exit 1
    }

    # Apply to Kubernetes if requested
    if ($Apply) {
        if (-not (Apply-KubernetesChanges)) {
            exit 1
        }
    }

    Write-Host ""
    Write-Host "🎉 CORS configuration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Configuration Status:" -ForegroundColor Cyan
    Write-Host "  ✅ ConfigMap: k8s/configmap.yaml" -ForegroundColor Green
    Write-Host "  ✅ Backend deployment: Updated with CORS environment variables" -ForegroundColor Green
    Write-Host "  ✅ Keycloak deployment: Updated with CORS environment variables" -ForegroundColor Green

    if ($UpdateEnv) {
        Write-Host "  ✅ Environment file: .env.local updated" -ForegroundColor Green
    }

    if (-not $Apply) {
        Write-Host ""
        Write-Host "💡 To apply changes to Kubernetes, run:" -ForegroundColor Cyan
        Write-Host "   ./scripts/configure-cors.ps1 -Apply" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "🌐 CORS Origins Configured:" -ForegroundColor Cyan
    Write-Host "  • http://localhost:3000 (Production frontend)" -ForegroundColor White
    Write-Host "  • http://localhost:5173 (Development frontend)" -ForegroundColor White
    Write-Host "  • https://localhost:3000 (HTTPS production)" -ForegroundColor White
    Write-Host "  • https://localhost:5173 (HTTPS development)" -ForegroundColor White

} catch {
    Write-Error "CORS configuration failed: $_"
    exit 1
}
