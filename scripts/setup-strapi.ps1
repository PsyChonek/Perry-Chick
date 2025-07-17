#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Initializes Strapi CMS for the Perry Chick project
.DESCRIPTION
    This script sets up Strapi CMS by building Docker images, deploying to Kubernetes,
    and providing instructions for first-time setup.
#>

param(
	[switch]$SkipBuild = $false,
	[switch]$RestartOnly = $false
)

Write-Host "🚀 Initializing Strapi CMS for Perry Chick..." -ForegroundColor Green
Write-Host ""

if (-not $RestartOnly) {
	# Generate Strapi secrets if they don't exist
	Write-Host "🔐 Checking Strapi secrets..." -ForegroundColor Yellow
	if (Select-String -Path ".env.local" -Pattern "strapi.*_change_me" -Quiet) {
		Write-Host "  ⚙️  Generating new Strapi secrets..." -ForegroundColor Cyan
		& "./scripts/generate-strapi-secrets.ps1"
		Write-Host ""
	}
 else {
		Write-Host "  ✅ Strapi secrets already configured" -ForegroundColor Green
		Write-Host ""
	}

	# Update Kubernetes configuration
	Write-Host "⚙️  Updating Kubernetes configuration..." -ForegroundColor Yellow
	& "./scripts/update-env-config.ps1" -Apply
	Write-Host ""

	if (-not $SkipBuild) {
		# Build Strapi Docker image
		Write-Host "🔨 Building Strapi Docker image..." -ForegroundColor Yellow
		& "./scripts/build-images.ps1" -UseMinikube
		Write-Host ""
	}
}

# Deploy or restart Strapi
if ($RestartOnly) {
	Write-Host "🔄 Restarting Strapi deployment..." -ForegroundColor Yellow
	kubectl rollout restart deployment/strapi
}
else {
	Write-Host "🚀 Deploying Strapi to Kubernetes..." -ForegroundColor Yellow
	kubectl apply -f k8s/deploy.yaml
}

Write-Host ""
Write-Host "⏳ Waiting for Strapi to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/strapi

if ($LASTEXITCODE -eq 0) {
	Write-Host "✅ Strapi deployment is ready!" -ForegroundColor Green
	Write-Host ""

	# Start port forwarding if not already running
	$strapiForward = Get-Job -Name "strapi-forward" -ErrorAction SilentlyContinue
	if (-not $strapiForward -or $strapiForward.State -ne "Running") {
		Write-Host "🌐 Starting port forwarding for Strapi..." -ForegroundColor Yellow
		Start-Job -Name "strapi-forward" -ScriptBlock {
			kubectl port-forward service/strapi 1337:1337 2>$null
		} | Out-Null
		Start-Sleep 3
	}

	Write-Host "📝 Strapi CMS is now available!" -ForegroundColor Green
	Write-Host ""
	Write-Host "🌐 Access URLs:" -ForegroundColor White
	Write-Host "  📝 Strapi Admin Panel: http://localhost:1337/admin" -ForegroundColor Cyan
	Write-Host "  🔌 Strapi API:         http://localhost:1337/api" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "🔧 First-time setup:" -ForegroundColor Yellow
	Write-Host "  1. Open http://localhost:1337/admin in your browser" -ForegroundColor Cyan
	Write-Host "  2. Create your first admin user account" -ForegroundColor Cyan
	Write-Host "  3. Configure content types for Perry Chick e-commerce:" -ForegroundColor Cyan
	Write-Host "     - Products (name, description, price, images, categories)" -ForegroundColor Gray
	Write-Host "     - Categories (name, description, slug)" -ForegroundColor Gray
	Write-Host "     - Pages (title, content, slug for CMS pages)" -ForegroundColor Gray
	Write-Host "     - Settings (site configuration)" -ForegroundColor Gray
	Write-Host ""
	Write-Host "📚 Useful commands:" -ForegroundColor White
	Write-Host "  Check logs: kubectl logs deployment/strapi" -ForegroundColor Magenta
	Write-Host "  Restart:    ./scripts/setup-strapi.ps1 -RestartOnly" -ForegroundColor Magenta
	Write-Host "  Rebuild:    ./scripts/setup-strapi.ps1" -ForegroundColor Magenta
	Write-Host ""
}
else {
	Write-Host "❌ Strapi deployment failed!" -ForegroundColor Red
	Write-Host ""
	Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
	Write-Host "  Check pod status: kubectl get pods -l app=strapi" -ForegroundColor Cyan
	Write-Host "  Check pod logs:   kubectl logs deployment/strapi" -ForegroundColor Cyan
	Write-Host "  Check events:     kubectl describe deployment strapi" -ForegroundColor Cyan
	exit 1
}
