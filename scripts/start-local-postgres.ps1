#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start PostgreSQL container for local development
.DESCRIPTION
    This script starts a PostgreSQL 15 container for local Perry Chick development.
    Uses the same database configuration as defined in .env.local
.PARAMETER Stop
    Stop the running PostgreSQL container instead of starting it
.PARAMETER Force
    Force remove existing container before starting a new one
.EXAMPLE
    .\start-local-postgres.ps1
    Start PostgreSQL container
.EXAMPLE
    .\start-local-postgres.ps1 -Stop
    Stop PostgreSQL container
.EXAMPLE
    .\start-local-postgres.ps1 -Force
    Force restart PostgreSQL container
#>

param(
	[switch]$Stop,
	[switch]$Force
)

# Container configuration
$ContainerName = "perrychick-postgres-local"
$PostgresUser = "perrychick"
$PostgresPassword = "db_password_change_me"
$PostgresDB = "perrychick_db"
$Port = "5432"
$Image = "postgres:15"

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

function Stop-PostgresContainer {
	Write-ColorOutput "🛑 Stopping PostgreSQL container..." $Yellow

	if (Test-ContainerRunning) {
		docker stop $ContainerName | Out-Null
		Write-ColorOutput "✅ PostgreSQL container stopped successfully" $Green
	}
 else {
		Write-ColorOutput "ℹ️  PostgreSQL container is not running" $Blue
	}

	if (Test-ContainerExists) {
		docker rm $ContainerName | Out-Null
		Write-ColorOutput "🗑️  Container removed" $Blue
	}
}

function Start-PostgresContainer {
	Write-ColorOutput "🚀 Starting PostgreSQL container for local development..." $Blue

	# Check if container is already running
	if (Test-ContainerRunning) {
		Write-ColorOutput "ℹ️  PostgreSQL container is already running" $Green
		Write-ColorOutput "   📍 Connection: localhost:$Port" $Blue
		Write-ColorOutput "   🔑 Database: $PostgresDB" $Blue
		Write-ColorOutput "   👤 User: $PostgresUser" $Blue
		return
	}

	# Remove existing container if it exists
	if (Test-ContainerExists) {
		Write-ColorOutput "🗑️  Removing existing container..." $Yellow
		docker rm $ContainerName | Out-Null
	}

	# Start new container
	try {
		Write-ColorOutput "📦 Pulling PostgreSQL image (if needed)..." $Blue
		docker pull $Image | Out-Null

		Write-ColorOutput "▶️  Starting container..." $Blue
		docker run -d `
			--name $ContainerName `
			-e "POSTGRES_USER=$PostgresUser" `
			-e "POSTGRES_PASSWORD=$PostgresPassword" `
			-e "POSTGRES_DB=$PostgresDB" `
			-p "${Port}:5432" `
			$Image | Out-Null

		# Wait for container to be ready
		Write-ColorOutput "⏳ Waiting for PostgreSQL to be ready..." $Yellow
		$retries = 30
		$ready = $false

		for ($i = 1; $i -le $retries; $i++) {
			try {
				$result = docker exec $ContainerName pg_isready -U $PostgresUser -d $PostgresDB 2>$null
				if ($LASTEXITCODE -eq 0) {
					$ready = $true
					break
				}
			}
			catch {
				# Continue waiting
			}

			Start-Sleep -Seconds 1
			Write-Progress -Activity "Waiting for PostgreSQL" -PercentComplete (($i / $retries) * 100)
		}

		Write-Progress -Completed -Activity "Waiting for PostgreSQL"

		if ($ready) {
			Write-ColorOutput "✅ PostgreSQL is ready for connections!" $Green
			Write-ColorOutput ""
			Write-ColorOutput "📋 Connection Details:" $Blue
			Write-ColorOutput "   🌐 Host: localhost" $Reset
			Write-ColorOutput "   🔌 Port: $Port" $Reset
			Write-ColorOutput "   🗃️  Database: $PostgresDB" $Reset
			Write-ColorOutput "   👤 Username: $PostgresUser" $Reset
			Write-ColorOutput "   🔑 Password: $PostgresPassword" $Reset
			Write-ColorOutput ""
			Write-ColorOutput "🔗 Connection String:" $Yellow
			Write-ColorOutput "   Host=localhost;Database=$PostgresDB;Username=$PostgresUser;Password=$PostgresPassword" $Reset
			Write-ColorOutput ""
			Write-ColorOutput "ℹ️  To stop: docker stop $ContainerName" $Blue
			Write-ColorOutput "ℹ️  Or use: .\start-local-postgres.ps1 -Stop" $Blue
		}
		else {
			Write-ColorOutput "❌ PostgreSQL failed to start within 30 seconds" $Red
			Write-ColorOutput "Check container logs: docker logs $ContainerName" $Yellow
		}

	}
	catch {
		Write-ColorOutput "❌ Failed to start PostgreSQL container: $($_.Exception.Message)" $Red
		exit 1
	}
}

# Main execution
Write-ColorOutput "🐘 Perry Chick - Local PostgreSQL Manager" $Blue
Write-ColorOutput "=" * 50 $Blue

# Check if Docker is running
if (-not (Test-DockerRunning)) {
	exit 1
}

if ($Stop) {
	Stop-PostgresContainer
}
elseif ($Force) {
	Stop-PostgresContainer
	Start-PostgresContainer
}
else {
	Start-PostgresContainer
}
