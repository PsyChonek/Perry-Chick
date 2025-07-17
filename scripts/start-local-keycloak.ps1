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
    .\start-local-keycloak.ps1
    Start Keycloak container
.EXAMPLE
    .\start-local-keycloak.ps1 -Stop
    Stop Keycloak container
.EXAMPLE
    .\start-local-keycloak.ps1 -Force
    Force restart Keycloak container
#>

param(
	[switch]$Stop,
	[switch]$Force,
	[switch]$ImportRealm
)

# Container configuration
$ContainerName = "perrychick-keycloak-local"
$KeycloakUser = "admin"
$KeycloakPassword = "admin_password_change_me"
$Port = "8080"
$Image = "quay.io/keycloak/keycloak:23.0"
$RealmFile = "perrychick-realm.json"

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
	param([string]$Message, [string]$Color = $Reset)
	Write-Host "$Color$Message$Reset"
}

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

	$realmConfig = @{
		realm                  = "perrychick"
		displayName            = "Perry Chick"
		enabled                = $true
		registrationAllowed    = $true
		loginWithEmailAllowed  = $true
		duplicateEmailsAllowed = $false
		resetPasswordAllowed   = $true
		editUsernameAllowed    = $false
		bruteForceProtected    = $true
		clients                = @(
			@{
				clientId                  = "perrychick-frontend"
				name                      = "Perry Chick Frontend"
				enabled                   = $true
				clientAuthenticatorType   = "client-secret"
				secret                    = "your_client_secret_here"
				standardFlowEnabled       = $true
				implicitFlowEnabled       = $false
				directAccessGrantsEnabled = $true
				serviceAccountsEnabled    = $false
				publicClient              = $true
				frontchannelLogout        = $true
				protocol                  = "openid-connect"
				attributes                = @{
					"saml.assertion.signature"                   = "false"
					"saml.force.post.binding"                    = "false"
					"saml.multivalued.roles"                     = "false"
					"saml.encrypt"                               = "false"
					"saml.server.signature"                      = "false"
					"saml.server.signature.keyinfo.ext"          = "false"
					"exclude.session.state.from.auth.response"   = "false"
					"saml_force_name_id_format"                  = "false"
					"saml.client.signature"                      = "false"
					"tls.client.certificate.bound.access.tokens" = "false"
					"saml.authnstatement"                        = "false"
					"display.on.consent.screen"                  = "false"
					"saml.onetimeuse.condition"                  = "false"
				}
				redirectUris              = @(
					"http://localhost:3000/*",
					"http://localhost:5173/*"
				)
				webOrigins                = @(
					"http://localhost:3000",
					"http://localhost:5173",
					"+"
				)
				defaultClientScopes       = @(
					"web-origins",
					"profile",
					"roles",
					"email"
				)
				optionalClientScopes      = @(
					"address",
					"phone",
					"offline_access",
					"microprofile-jwt"
				)
			}
		)
		roles                  = @{
			realm = @(
				@{
					name        = "admin"
					description = "Administrator role"
				},
				@{
					name        = "user"
					description = "Regular user role"
				},
				@{
					name        = "farmer"
					description = "Farmer role with chick management permissions"
				}
			)
		}
		users                  = @(
			@{
				username      = "admin"
				enabled       = $true
				firstName     = "Admin"
				lastName      = "User"
				email         = "admin@perrychick.com"
				emailVerified = $true
				credentials   = @(
					@{
						type      = "password"
						value     = "admin123"
						temporary = $false
					}
				)
				realmRoles    = @(
					"admin",
					"user"
				)
			},
			@{
				username      = "farmer1"
				enabled       = $true
				firstName     = "John"
				lastName      = "Farmer"
				email         = "farmer@perrychick.com"
				emailVerified = $true
				credentials   = @(
					@{
						type      = "password"
						value     = "farmer123"
						temporary = $false
					}
				)
				realmRoles    = @(
					"farmer",
					"user"
				)
			}
		)
	}

	$json = $realmConfig | ConvertTo-Json -Depth 10
	$json | Out-File -FilePath $RealmFile -Encoding utf8
	Write-ColorOutput "✅ Realm configuration created: $RealmFile" $Green
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
			-e "KEYCLOAK_ADMIN=$KeycloakUser" `
			-e "KEYCLOAK_ADMIN_PASSWORD=$KeycloakPassword" `
			-e "KC_HTTP_ENABLED=true" `
			-e "KC_HOSTNAME_STRICT=false" `
			-e "KC_HOSTNAME_STRICT_HTTPS=false" `
			-e "KC_HEALTH_ENABLED=true" `
			-e "KC_METRICS_ENABLED=true" `
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
	Write-ColorOutput "      Roles: admin, user" $Reset
	Write-ColorOutput ""
	Write-ColorOutput "   🌾 Farmer User:" $Reset
	Write-ColorOutput "      Username: farmer1" $Reset
	Write-ColorOutput "      Password: farmer123" $Reset
	Write-ColorOutput "      Roles: farmer, user" $Reset
	Write-ColorOutput ""
	Write-ColorOutput "ℹ️  To stop: docker stop $ContainerName" $Blue
	Write-ColorOutput "ℹ️  Or use: .\start-local-keycloak.ps1 -Stop" $Blue
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
