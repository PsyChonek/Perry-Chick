#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update Kubernetes ConfigMap and Secrets from .env.kubernetes file
.DESCRIPTION
    This script synchronizes environment variables from .env.kubernetes to Kubernetes ConfigMap and Secrets.
    Non-sensitive values go to ConfigMap, sensitive values go to Secrets.
    It can also apply the changes to Kubernetes and restart deployments.
.PARAMETER Apply
    Apply the generated ConfigMap and Secrets to Kubernetes
.PARAMETER Restart
    Restart deployments after applying configuration (requires -Apply)
.PARAMETER Backup
    Create backup of existing ConfigMap and Secrets before updating
.PARAMETER EnvFile
    Path to the environment file (default: .env.kubernetes)
.EXAMPLE
    .\update-env-config.ps1
    Generate ConfigMap and Secrets (dry run)
.EXAMPLE
    .\update-env-config.ps1 -Apply
    Generate and apply to Kubernetes
.EXAMPLE
    .\update-env-config.ps1 -Apply -Restart
    Generate, apply, and restart deployments
.EXAMPLE
    .\update-env-config.ps1 -Apply -Restart -Backup
    Create backups, generate, apply, and restart deployments
#>

param(
    [switch]$Apply,
    [switch]$Restart,
    [switch]$Backup,
    [string]$EnvFile = ".env.kubernetes",
    [string]$ConfigMapName = "perrychick-config",
    [string]$SecretName = "perrychick-secrets",
    [string]$ConfigMapFile = "k8s/configmap.yaml",
    [string]$SecretFile = "k8s/secrets-generated.yaml"
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Cyan = "`e[36m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = $Reset)
    Write-Host "$Color$Message$Reset"
}

function Test-KubectlAvailable {
    try {
        kubectl version --client=true --output=yaml | Out-Null
        return $true
    }
    catch {
        Write-ColorOutput "❌ kubectl is not available or not configured!" $Red
        Write-ColorOutput "Please ensure kubectl is installed and configured." $Yellow
        return $false
    }
}

function Create-Backup {
    param([string]$ResourceType, [string]$ResourceName, [string]$BackupDir)

    if (!(Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = "$BackupDir/$ResourceType-$ResourceName-$timestamp.yaml"

    try {
        kubectl get $ResourceType $ResourceName -o yaml > $backupFile 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✓ Backed up $ResourceType/$ResourceName to $backupFile" $Cyan
        }
    }
    catch {
        Write-ColorOutput "  ⚠️  Could not backup $ResourceType/$ResourceName (may not exist)" $Yellow
    }
}

function Generate-ConfigMap {
    param([hashtable]$ConfigData)

    Write-ColorOutput "📝 Generating ConfigMap..." $Blue

    # Define sensitive keys that should go to Secrets instead
    $sensitiveKeys = @(
        "POSTGRES_PASSWORD",
        "KC_ADMIN_PASSWORD",
        "KC_DB_PASSWORD",
        "KC_CLIENT_SECRET",
        "REDIS_PASSWORD",
        "SENDGRID_API_KEY",
        "DATABASE_URL",
        "GRAFANA_ADMIN_PASSWORD"
    )

    $configMapData = @{}

    foreach ($key in $ConfigData.Keys) {
        if ($sensitiveKeys -notcontains $key) {
            # Use the value as-is from the environment file
            $configMapData[$key] = $ConfigData[$key]
            Write-ColorOutput "  ✓ Added to ConfigMap: $key" $Cyan
        }
    }

    # Generate YAML
    $yaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: $ConfigMapName
  namespace: default
data:
"@

    foreach ($key in $configMapData.Keys | Sort-Object) {
        $value = $configMapData[$key]
        $yaml += "`n  $key`: `"$value`""
    }

    # Ensure k8s directory exists
    if (!(Test-Path "k8s")) {
        New-Item -ItemType Directory -Path "k8s" | Out-Null
    }

    # Write ConfigMap file
    $yaml | Out-File -FilePath $ConfigMapFile -Encoding utf8
    Write-ColorOutput "✅ ConfigMap generated: $ConfigMapFile" $Green
}

function Generate-Secrets {
    param([hashtable]$ConfigData)

    Write-ColorOutput "🔐 Generating Secrets..." $Blue

    # Define sensitive keys
    $sensitiveKeys = @(
        "POSTGRES_PASSWORD",
        "KC_ADMIN_PASSWORD",
        "KC_DB_PASSWORD",
        "KC_CLIENT_SECRET",
        "REDIS_PASSWORD",
        "SENDGRID_API_KEY",
        "DATABASE_URL",
        "GRAFANA_ADMIN_PASSWORD"
    )

    $secrets = @{}

    foreach ($key in $ConfigData.Keys) {
        if ($sensitiveKeys -contains $key) {
            $value = $ConfigData[$key]
            if ($value -ne "" -and $value -notmatch "^(your_.*_here|change_me)$") {
                # Convert to base64
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($value)
                $base64 = [System.Convert]::ToBase64String($bytes)
                $secrets[$key] = $base64
                Write-ColorOutput "  ✓ Added to Secrets: $key" $Cyan
            }
        }
    }

    if ($secrets.Count -eq 0) {
        Write-ColorOutput "⚠️  No valid secrets found to generate" $Yellow
        return
    }

    # Generate YAML
    $yaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: $SecretName
  namespace: default
type: Opaque
data:
"@

    foreach ($key in $secrets.Keys | Sort-Object) {
        $yaml += "`n  $key`: $($secrets[$key])"
    }

    # Write Secrets file
    $yaml | Out-File -FilePath $SecretFile -Encoding utf8
    Write-ColorOutput "✅ Secrets generated: $SecretFile" $Green
}

function Create-KeycloakRealmConfigMap {
    Write-ColorOutput "🔐 Creating Keycloak Realm ConfigMap..." $Blue

    $realmFile = "perrychick-realm-local.json"

    if (!(Test-Path $realmFile)) {
        Write-ColorOutput "  ⚠️  Realm file not found: $realmFile" $Yellow
        Write-ColorOutput "  Skipping Keycloak realm ConfigMap creation" $Yellow
        return $true
    }

    # Delete existing ConfigMap if it exists
    kubectl delete configmap keycloak-realm-config 2>$null | Out-Null

    # Create ConfigMap from file
    kubectl create configmap keycloak-realm-config --from-file=realm.json=$realmFile

    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "  ✅ Keycloak realm ConfigMap created successfully" $Green
        return $true
    } else {
        Write-ColorOutput "  ❌ Failed to create Keycloak realm ConfigMap" $Red
        return $false
    }
}

function Apply-ToKubernetes {
    Write-ColorOutput "🚀 Applying configuration to Kubernetes..." $Blue

    # Apply ConfigMap
    if (Test-Path $ConfigMapFile) {
        kubectl apply -f $ConfigMapFile
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✅ ConfigMap applied successfully" $Green
        } else {
            Write-ColorOutput "  ❌ Failed to apply ConfigMap" $Red
            return $false
        }
    }

    # Apply Secrets
    if (Test-Path $SecretFile) {
        kubectl apply -f $SecretFile
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✅ Secrets applied successfully" $Green
        } else {
            Write-ColorOutput "  ❌ Failed to apply Secrets" $Red
            return $false
        }
    }

    # Create Keycloak Realm ConfigMap from file
    $realmSuccess = Create-KeycloakRealmConfigMap
    if (!$realmSuccess) {
        Write-ColorOutput "  ⚠️  Keycloak realm ConfigMap creation failed, but continuing..." $Yellow
    }

    return $true
}

function Restart-Deployments {
    Write-ColorOutput "🔄 Restarting deployments..." $Blue

    $deployments = @(
        "backend",
        "frontend",
        "notifications",
        "keycloak",
        "grafana"
    )

    foreach ($deployment in $deployments) {
        Write-ColorOutput "  🔄 Restarting $deployment..." $Yellow
        kubectl rollout restart deployment/$deployment 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "    ✅ $deployment restarted" $Green
        } else {
            Write-ColorOutput "    ⚠️  $deployment restart failed (may not exist)" $Yellow
        }
    }
}

# Main execution
Write-ColorOutput "🔧 Perry Chick - Environment Configuration Manager" $Blue
Write-ColorOutput "=" * 60 $Blue

# Check if .env.local exists
if (!(Test-Path $EnvFile)) {
    Write-ColorOutput "❌ Error: $EnvFile not found!" $Red
    Write-ColorOutput "Please ensure you have a $EnvFile file in the root directory." $Yellow
    exit 1
}

# Read environment file
Write-ColorOutput "📁 Reading environment variables from $EnvFile..." $Blue
$envContent = Get-Content $EnvFile
$configData = @{}

foreach ($line in $envContent) {
    if ($line -match "^([^#][^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()

        # Remove quotes if present
        $value = $value -replace '^"(.*)"$', '$1'
        $value = $value -replace "^'(.*)'$", '$1'

        if ($value -ne "") {
            $configData[$key] = $value
        }
    }
}

Write-ColorOutput "📊 Found $($configData.Count) environment variables" $Cyan

# Create backups if requested
if ($Backup -and $Apply) {
    if (Test-KubectlAvailable) {
        Write-ColorOutput "💾 Creating backups..." $Blue
        Create-Backup "configmap" $ConfigMapName "backups"
        Create-Backup "secret" $SecretName "backups"
    }
}

# Generate ConfigMap and Secrets
Generate-ConfigMap $configData
Generate-Secrets $configData

# Apply to Kubernetes if requested
if ($Apply) {
    if (Test-KubectlAvailable) {
        $success = Apply-ToKubernetes

        # Restart deployments if requested and apply was successful
        if ($Restart -and $success) {
            Start-Sleep -Seconds 2
            Restart-Deployments
        }
    } else {
        Write-ColorOutput "❌ Cannot apply to Kubernetes - kubectl not available" $Red
        exit 1
    }
} else {
    Write-ColorOutput ""
    Write-ColorOutput "ℹ️  Configuration files generated (dry run)" $Blue
    Write-ColorOutput "   To apply: .\update-env-config.ps1 -Apply" $Yellow
    Write-ColorOutput "   To apply and restart: .\update-env-config.ps1 -Apply -Restart" $Yellow
}

Write-ColorOutput ""
Write-ColorOutput "✅ Environment configuration update completed!" $Green
