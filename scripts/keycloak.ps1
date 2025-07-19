#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start Keycloak container for local development
.DESCRIPTION
    This script starts a Keycloak container configured for Perry Chick development.
    It includes realm import and proper configuration for local development.
.PARAMETER Stop
    Stop the running Keycloak container instead of starting it
.PARAMETER Force
    Force remove existing container before starting a new one
.PARAMETER ImportRealm
    Force re-import the realm configuration
.EXAMPLE
    .\keycloak.ps1
    Start Keycloak container
.EXAMPLE
    .\keycloak.ps1 -Stop
    Stop Keycloak container
.EXAMPLE
    .\keycloak.ps1 -Force
    Force restart Keycloak container
#>

param(
	[switch]$Stop,
	[switch]$Force,
	[switch]$ImportRealm
)

# Container configuration - defaults that will be overridden by env vars
$ContainerName = "perrychick-keycloak-local"
$KeycloakUser = "admin"
$KeycloakPassword = "admin_password_change_me"
$Port = "8080"
$Image = "quay.io/keycloak/keycloak:23.0"
$RealmFile = "perrychick-realm.json"

function Write-ColorOutput {
	param([string]$Message, [string]$Color = $Reset)
	Write-Host "$Color$Message$Reset"
}

# Load environment variables from .env.local if it exists
$EnvFile = ".env.local"
if (Test-Path $EnvFile) {
	Write-ColorOutput "📁 Loading environment variables from $EnvFile..." $Blue
	Get-Content $EnvFile | ForEach-Object {
		if ($_ -match "^([^#][^=]+)=(.*)$") {
			$key = $Matches[1].Trim()
			$value = $Matches[2].Trim()
			[Environment]::SetEnvironmentVariable($key, $value, "Process")
		}
	}

	# Override defaults with environment values if they exist
	if ($env:KC_ADMIN) { $KeycloakUser = $env:KC_ADMIN }
	if ($env:KC_ADMIN_PASSWORD) { $KeycloakPassword = $env:KC_ADMIN_PASSWORD }
	if ($env:KC_CONTAINER_NAME) { $ContainerName = $env:KC_CONTAINER_NAME }
	if ($env:KC_PORT) { $Port = $env:KC_PORT }
	if ($env:KC_IMAGE) { $Image = $env:KC_IMAGE }
	if ($env:KC_REALM_FILE) { $RealmFile = $env:KC_REALM_FILE }
}

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Test-DockerRunning {
	try {
		docker version | Out-Null
		return $true
	}
	catch {
		Write-ColorOutput "❌ Docker is not running or not installed!" $Red
		Write-ColorOutput "Please start Docker Desktop and try again." $Yellow
		return $false
	}
}

function Test-ContainerExists {
	$exists = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }
	return [bool]$exists
}

function Test-ContainerRunning {
	$running = docker ps --filter "name=$ContainerName" --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }
	return [bool]$running
}

function Stop-KeycloakContainer {
	Write-ColorOutput "🛑 Stopping Keycloak container..." $Yellow

	if (Test-ContainerRunning) {
		docker stop $ContainerName | Out-Null
		Write-ColorOutput "✅ Keycloak container stopped successfully" $Green
	}
 else {
		Write-ColorOutput "ℹ️  Keycloak container is not running" $Blue
	}

	if (Test-ContainerExists) {
		docker rm $ContainerName | Out-Null
		Write-ColorOutput "🗑️  Container removed" $Blue
	}
}

function Create-RealmConfig {
	Write-ColorOutput "📝 Creating realm configuration..." $Blue

	$templateFile = "perrychick-realm-local.json"

	# Check if template file exists
	if (Test-Path $templateFile) {
		Write-ColorOutput "📄 Using realm template: $templateFile" $Cyan

		# Read template and replace environment variables
		$templateContent = Get-Content $templateFile -Raw

		# Replace environment variables in template
		$realmName = $env:KC_REALM ?? "perrychick"
		$clientId = $env:KC_CLIENT_ID ?? "perrychick-frontend"
		$clientSecret = $env:KC_CLIENT_SECRET ?? "your_client_secret_here"
		$frontendUrl = $env:FRONTEND_URL ?? "http://localhost:3000"
		$viteDevUrl = "http://localhost:5173"  # Vite dev server

		# Replace placeholders in template
		$realmContent = $templateContent `
			-replace '"realm":\s*"[^"]*"', "`"realm`": `"$realmName`"" `
			-replace '"clientId":\s*"[^"]*"', "`"clientId`": `"$clientId`"" `
			-replace '"secret":\s*"[^"]*"', "`"secret`": `"$clientSecret`""

		# Update redirect URIs and web origins with current URLs
		$redirectUris = @(
			"$frontendUrl/*",
			"$viteDevUrl/*"
		)
		$webOrigins = @(
			$frontendUrl,
			$viteDevUrl,
			"+"
		)

		# Parse JSON to update arrays
		$realmConfig = $realmContent | ConvertFrom-Json
		$realmConfig.clients[0].redirectUris = $redirectUris
		$realmConfig.clients[0].webOrigins = $webOrigins

		# Convert back to JSON
		$json = $realmConfig | ConvertTo-Json -Depth 10

		$json | Out-File -FilePath $RealmFile -Encoding utf8
		Write-ColorOutput "✅ Realm configuration created: $RealmFile" $Green
	}
	else {
		Write-ColorOutput "❌ Error: Template file not found: $templateFile" $Red
		Write-ColorOutput "Please ensure the realm template file exists in the root directory." $Yellow
		throw "Template file '$templateFile' not found"
	}
}

function Start-KeycloakContainer {
	Write-ColorOutput "🔐 Starting Keycloak container for local development..." $Blue

	# Check if container is already running
	if (Test-ContainerRunning) {
		Write-ColorOutput "ℹ️  Keycloak container is already running" $Green
		Show-ConnectionInfo
		return
	}

	# Remove existing container if it exists
	if (Test-ContainerExists) {
		Write-ColorOutput "🗑️  Removing existing container..." $Yellow
		docker rm $ContainerName | Out-Null
	}

	# Create realm configuration if it doesn't exist or ImportRealm is specified
	if (-not (Test-Path $RealmFile) -or $ImportRealm) {
		Create-RealmConfig
	}

	# Start new container
	try {
		Write-ColorOutput "📦 Pulling Keycloak image (if needed)..." $Blue
		docker pull $Image | Out-Null

		Write-ColorOutput "▶️  Starting container..." $Blue

		# Get absolute path to realm file
		$realmPath = (Resolve-Path $RealmFile).Path

		docker run -d `
			--name $ContainerName `
			-e "KC_ADMIN=$KeycloakUser" `
			-e "KC_ADMIN_PASSWORD=$KeycloakPassword" `
			-e "KC_HTTP_ENABLED=true" `
			-e "KC_HOSTNAME_STRICT=false" `
			-e "KC_HOSTNAME_STRICT_HTTPS=false" `
			-e "KC_HEALTH_ENABLED=true" `
			-e "KC_METRICS_ENABLED=true" `
			-e "KC_HTTP_CORS_ENABLED=$($env:KC_HTTP_CORS_ENABLED ?? 'true')" `
			-e "KC_HTTP_CORS_ORIGINS=$($env:KC_HTTP_CORS_ORIGINS ?? 'http://localhost:5173,http://localhost:3000,http://localhost:8080')" `
			-e "KC_HTTP_CORS_METHODS=$($env:KC_HTTP_CORS_METHODS ?? 'GET,POST,PUT,DELETE,OPTIONS')" `
			-e "KC_HTTP_CORS_HEADERS=$($env:KC_HTTP_CORS_HEADERS ?? 'Origin,Accept,X-Requested-With,Content-Type,Access-Control-Request-Method,Access-Control-Request-Headers,Authorization')" `
			-p "${Port}:8080" `
			-v "${realmPath}:/opt/keycloak/data/import/realm.json:ro" `
			$Image `
			start-dev --import-realm | Out-Null

		# Wait for container to be ready
		Write-ColorOutput "⏳ Waiting for Keycloak to be ready..." $Yellow
		$retries = 60
		$ready = $false

		for ($i = 1; $i -le $retries; $i++) {
			try {
				$response = Invoke-WebRequest -Uri "http://localhost:$Port/health/ready" -Method GET -UseBasicParsing -TimeoutSec 5 2>$null
				if ($response.StatusCode -eq 200) {
					$ready = $true
					break
				}
			}
			catch {
				# Continue waiting
			}

			Start-Sleep -Seconds 2
			Write-Progress -Activity "Waiting for Keycloak" -PercentComplete (($i / $retries) * 100)
		}

		Write-Progress -Completed -Activity "Waiting for Keycloak"

		if ($ready) {
			Write-ColorOutput "✅ Keycloak is ready!" $Green
			Show-ConnectionInfo
			Show-TestUsers
		}
		else {
			Write-ColorOutput "❌ Keycloak failed to start within 2 minutes" $Red
			Write-ColorOutput "Check container logs: docker logs $ContainerName" $Yellow
		}

	}
	catch {
		Write-ColorOutput "❌ Failed to start Keycloak container: $($_.Exception.Message)" $Red
		exit 1
	}
}

function Show-ConnectionInfo {
	Write-ColorOutput ""
	Write-ColorOutput "📋 Keycloak Connection Details:" $Blue
	Write-ColorOutput "   🌐 Admin Console: http://localhost:$Port/admin" $Reset
	Write-ColorOutput "   👤 Admin Username: $KeycloakUser" $Reset
	Write-ColorOutput "   🔑 Admin Password: $KeycloakPassword" $Reset
	Write-ColorOutput ""
	Write-ColorOutput "🔗 Realm Details:" $Yellow
	Write-ColorOutput "   🏰 Realm: perrychick" $Reset
	Write-ColorOutput "   📱 Client ID: perrychick-frontend" $Reset
	Write-ColorOutput "   🌍 Auth URL: http://localhost:$Port/realms/perrychick" $Reset
	Write-ColorOutput ""
}

function Show-TestUsers {
	Write-ColorOutput "👥 Test Users:" $Green
	Write-ColorOutput "   🔑 Admin User:" $Reset
	Write-ColorOutput "      Username: admin" $Reset
	Write-ColorOutput "      Password: admin123" $Reset
	Write-ColorOutput "      KeycloakId: admin-keycloak-id" $Reset
	Write-ColorOutput "      Roles: admin, user" $Reset
	Write-ColorOutput ""
	Write-ColorOutput "   🌾 Farmer User:" $Reset
	Write-ColorOutput "      Username: farmer1" $Reset
	Write-ColorOutput "      Password: farmer123" $Reset
	Write-ColorOutput "      KeycloakId: farmer1-keycloak-id" $Reset
	Write-ColorOutput "      Roles: farmer, user" $Reset
	Write-ColorOutput ""
	Write-ColorOutput "ℹ️  To stop: docker stop $ContainerName" $Blue
	Write-ColorOutput "ℹ️  Or use: .\keycloak.ps1 -Stop" $Blue
}

# Main execution
Write-ColorOutput "🔐 Perry Chick - Local Keycloak Manager" $Blue
Write-ColorOutput "=" * 50 $Blue

# Check if Docker is running
if (-not (Test-DockerRunning)) {
	exit 1
}

if ($Stop) {
	Stop-KeycloakContainer
}
elseif ($Force) {
	Stop-KeycloakContainer
	Start-KeycloakContainer
}
else {
	Start-KeycloakContainer
}
