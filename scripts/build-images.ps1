#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Builds Docker images for Perry Chick application components
.DESCRIPTION
    This script builds the Docker images for the backend, frontend, and notifications
    services in Minikube's Docker environment.
#>

param(
	[switch]$UseMinikube = $true
)

Write-Host "🐳 Building Perry Chick Docker Images..." -ForegroundColor Green

# Update environment configuration first
Write-Host "📝 Updating environment configuration..." -ForegroundColor Yellow
./scripts/update-env-config.ps1 -Apply

# Configure Docker to use Minikube's Docker daemon if requested
if ($UseMinikube) {
	Write-Host "⚙️  Configuring Docker to use Minikube's daemon..." -ForegroundColor Yellow
	try {
		# Check if Minikube is running
		$minikubeStatus = minikube status --format="{{.Host}}" 2>$null
		if ($minikubeStatus -ne "Running") {
			Write-Host "❌ Minikube is not running. Please start Minikube first." -ForegroundColor Red
			Write-Host "   Run: minikube start" -ForegroundColor Cyan
			exit 1
		}

		# Use minikube docker-env to set environment
		Write-Host "Setting Docker environment for Minikube..." -ForegroundColor Gray
		& minikube docker-env --shell powershell | Invoke-Expression

		# Verify Docker connection
		docker version --format "{{.Server.Version}}" 2>$null | Out-Null
		if ($LASTEXITCODE -eq 0) {
			Write-Host "✅ Successfully configured to use Minikube's Docker daemon" -ForegroundColor Green
		}
		else {
			Write-Host "⚠️  Docker connection failed, using local Docker" -ForegroundColor Yellow
		}
	}
	catch {
		Write-Host "⚠️  Failed to configure Minikube Docker environment: $($_.Exception.Message)" -ForegroundColor Yellow
		Write-Host "   Using local Docker instead" -ForegroundColor Yellow
	}
}

# Check if Dockerfiles exist
$dockerFiles = @(
	@{ Name = "Backend"; Path = "backend/Dockerfile"; Image = "perrychick-backend:latest" },
	@{ Name = "Frontend"; Path = "frontend/Dockerfile"; Image = "perrychick-frontend:latest" },
	@{ Name = "Notifications"; Path = "notifications/Dockerfile"; Image = "perrychick-notifications:latest" }
)

foreach ($dockerfile in $dockerFiles) {
	if (Test-Path $dockerfile.Path) {
		Write-Host "🔨 Building $($dockerfile.Name) image..." -ForegroundColor Cyan
		$context = Split-Path $dockerfile.Path -Parent

		try {
			docker build -t $dockerfile.Image $context
			if ($LASTEXITCODE -eq 0) {
				Write-Host "  ✅ Successfully built $($dockerfile.Image)" -ForegroundColor Green
			}
			else {
				Write-Host "  ❌ Failed to build $($dockerfile.Image)" -ForegroundColor Red
				exit 1
			}
		}
		catch {
			Write-Host "  ❌ Error building $($dockerfile.Image): $_" -ForegroundColor Red
			exit 1
		}
	}
 else {
		Write-Host "  ⚠️  Dockerfile not found: $($dockerfile.Path)" -ForegroundColor Yellow
	}
}

Write-Host ""
Write-Host "🎉 All Docker images built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Built images:" -ForegroundColor White
docker images | Select-String "perrychick-"

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update your Kubernetes deployment: kubectl apply -f k8s/deploy.yaml" -ForegroundColor Cyan
Write-Host "  2. Or run: kubectl rollout restart deployment/perrychick-backend deployment/perrychick-frontend deployment/perrychick-notifications" -ForegroundColor Cyan
