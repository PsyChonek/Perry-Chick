#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Manages Minikube cluster for Perry Chick development
.DESCRIPTION
    Start, stop, or restart Minikube cluster with Perry Chick configuration.
    When starting, optionally builds images and deploys the full application.
.PARAMETER Stop
    Stop the Minikube cluster
.PARAMETER Restart
    Restart the Minikube cluster (stop then start)
.PARAMETER SkipBuild
    When starting, skip building Docker images
.PARAMETER SkipDeploy
    When starting, skip deploying the application
.EXAMPLE
    .\minikube.ps1
    Start Minikube and deploy Perry Chick
.EXAMPLE
    .\minikube.ps1 -Stop
    Stop Minikube cluster
.EXAMPLE
    .\minikube.ps1 -Restart
    Restart Minikube cluster and redeploy
.EXAMPLE
    .\minikube.ps1 -SkipBuild -SkipDeploy
    Start Minikube only (no build or deploy)
#>

param(
	[switch]$Stop,
	[switch]$Restart,
	[switch]$SkipBuild,
	[switch]$SkipDeploy
)

if ($Stop) {
	Write-Host '🛑 Stopping Minikube cluster...' -ForegroundColor Yellow

	# Stop port forwarding jobs
	Write-Host '🧹 Cleaning up port forwarding jobs...' -ForegroundColor Yellow
	Get-Job | Where-Object { $_.Name -like "*-forward" } | Stop-Job -ErrorAction SilentlyContinue
	Get-Job | Where-Object { $_.Name -like "*-forward" } | Remove-Job -ErrorAction SilentlyContinue

	# Stop Minikube
	minikube stop

	if ($LASTEXITCODE -eq 0) {
		Write-Host '✅ Minikube stopped successfully' -ForegroundColor Green
	}
 else {
		Write-Host '❌ Failed to stop Minikube' -ForegroundColor Red
		exit 1
	}

	exit 0
}

if ($Restart) {
	Write-Host '🔄 Restarting Minikube cluster...' -ForegroundColor Green

	# Stop first
	Write-Host 'Step 1: Stopping existing Minikube...' -ForegroundColor Yellow
	minikube delete 2>$null

	# Then start (continue with normal start process)
	Write-Host 'Step 2: Starting fresh Minikube...' -ForegroundColor Yellow
}
else {
	Write-Host '🚀 Starting Minikube cluster for Perry Chick...' -ForegroundColor Green

	# Check if Minikube is already running
	$minikubeStatus = minikube status 2>$null
	if ($LASTEXITCODE -eq 0 -and $minikubeStatus -match "Running") {
		Write-Host '✅ Minikube is already running' -ForegroundColor Green

		if ($SkipBuild -and $SkipDeploy) {
			Write-Host 'Nothing to do - Minikube is running and build/deploy skipped' -ForegroundColor Gray
			exit 0
		}
	}
	else {
		Write-Host 'Starting Minikube with network configuration...' -ForegroundColor Yellow
		minikube start --driver=docker --dns-domain=cluster.local --extra-config=kubelet.cluster-dns=10.96.0.10 --extra-config=kubelet.cluster-domain=cluster.local --memory=4096 --cpus=2

		if ($LASTEXITCODE -ne 0) {
			Write-Host '❌ Failed to start Minikube' -ForegroundColor Red
			exit 1
		}

		# Wait for API server to be ready
		Write-Host 'Waiting for Kubernetes API server to be ready...' -ForegroundColor Yellow
		$retryCount = 0
		$maxRetries = 30
		do {
			Start-Sleep -Seconds 5
			$retryCount++
			Write-Host "  Checking API server readiness... (attempt $retryCount/$maxRetries)" -ForegroundColor Gray

			kubectl cluster-info 2>$null | Out-Null
			if ($LASTEXITCODE -eq 0) {
				Write-Host '✅ Kubernetes API server is ready' -ForegroundColor Green
				break
			}

			if ($retryCount -ge $maxRetries) {
				Write-Host '❌ Kubernetes API server failed to become ready within timeout' -ForegroundColor Red
				Write-Host '💡 You can try running the script again or check: minikube status' -ForegroundColor Yellow
				exit 1
			}
		} while ($true)
	}
}# Build images if not skipped
if (-not $SkipBuild) {
	Write-Host 'Step 3: Building Docker images...' -ForegroundColor Yellow
	./scripts/build-images.ps1 -UseMinikube

	if ($LASTEXITCODE -ne 0) {
		Write-Host '❌ Failed to build images' -ForegroundColor Red
		exit 1
	}
}

# Deploy application if not skipped
if (-not $SkipDeploy) {
	Write-Host 'Step 4: Deploying application...' -ForegroundColor Yellow
	./scripts/deploy-full.ps1

	if ($LASTEXITCODE -ne 0) {
		Write-Host '❌ Failed to deploy application' -ForegroundColor Red
		exit 1
	}
}

Write-Host ''
Write-Host '🎉 Minikube setup complete!' -ForegroundColor Green
Write-Host ''
Write-Host '🌐 Next steps:' -ForegroundColor Cyan
Write-Host '  1. Set up port forwarding: ./scripts/forward-all-services.ps1' -ForegroundColor White
Write-Host '  2. Access services at:' -ForegroundColor White
Write-Host '     - Frontend: http://localhost:3000' -ForegroundColor Gray
Write-Host '     - Backend API: http://localhost:5006' -ForegroundColor Gray
Write-Host '     - Grafana: http://localhost:3001' -ForegroundColor Gray
Write-Host ''
