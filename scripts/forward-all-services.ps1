#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Sets up port forwarding for all Perry Chick services
.DESCRIPTION
    This script starts background jobs to forward ports for all Perry Chick services
    and displays the available URLs.
#>

Write-Host "🌐 Setting up port forwarding for all Perry Chick services..." -ForegroundColor Green
Write-Host ""

# Stop any existing port forwarding jobs first
Write-Host "🧹 Cleaning up existing port forwarding jobs..." -ForegroundColor Yellow
Get-Job | Where-Object { $_.Name -like "*-forward" } | Stop-Job -ErrorAction SilentlyContinue
Get-Job | Where-Object { $_.Name -like "*-forward" } | Remove-Job -ErrorAction SilentlyContinue

Write-Host "🚀 Starting port forwarding in background..." -ForegroundColor Yellow

# Start port forwarding jobs for each service
$services = @(
    @{ Name = "frontend-forward"; Service = "perrychick-frontend"; Port = "3000:3000" },
    @{ Name = "backend-forward"; Service = "perrychick-backend"; Port = "5000:5000" },
    @{ Name = "notifications-forward"; Service = "perrychick-notifications"; Port = "5003:5003" },
    @{ Name = "keycloak-forward"; Service = "keycloak"; Port = "8080:8080" },
    @{ Name = "postgres-forward"; Service = "postgres"; Port = "5432:5432" },
    @{ Name = "redis-forward"; Service = "redis"; Port = "6379:6379" },
    @{ Name = "strapi-forward"; Service = "strapi"; Port = "1337:1337" },
    @{ Name = "grafana-forward"; Service = "grafana"; Port = "3001:3000" },
    @{ Name = "prometheus-forward"; Service = "prometheus"; Port = "9090:9090" },
    @{ Name = "jaeger-forward"; Service = "jaeger-query"; Port = "16686:16686" },
    @{ Name = "otel-collector-forward"; Service = "otel-collector"; Port = "4317:4317" }
)

foreach ($svc in $services) {
    try {
        Start-Job -Name $svc.Name -ScriptBlock {
            param($serviceName, $portMapping)
            kubectl port-forward service/$serviceName $portMapping 2>$null
        } -ArgumentList $svc.Service, $svc.Port | Out-Null
        Write-Host "  ✓ Started forwarding for $($svc.Service)" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ Failed to start forwarding for $($svc.Service)" -ForegroundColor Red
    }
}

# Wait a moment for jobs to start
Start-Sleep 3

# Display the available services
Write-Host ""
Write-Host "🌐 Perry Chick Services Available:" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Core Services:" -ForegroundColor White
Write-Host "  📱 Frontend:      http://localhost:3000" -ForegroundColor Cyan
Write-Host "  🔌 Backend API:   http://localhost:5000" -ForegroundColor Cyan
Write-Host "  📧 Notifications: http://localhost:5003" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 Infrastructure:" -ForegroundColor White
Write-Host "  🔐 Keycloak:      http://localhost:8080" -ForegroundColor Cyan
Write-Host "  🗄️  PostgreSQL:    localhost:5432" -ForegroundColor Cyan
Write-Host "  🔴 Redis:         localhost:6379" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Content & Monitoring:" -ForegroundColor White
Write-Host "  📝 Strapi CMS:    http://localhost:1337" -ForegroundColor Yellow
Write-Host "  📊 Grafana:       http://localhost:3001" -ForegroundColor Yellow
Write-Host "  📈 Prometheus:    http://localhost:9090" -ForegroundColor Yellow
Write-Host "  🔍 Jaeger:        http://localhost:16686" -ForegroundColor Yellow
Write-Host "  📡 OTEL Collector: localhost:4317 (gRPC)" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Management:" -ForegroundColor White
Write-Host "  To stop port forwarding: Get-Job | Stop-Job; Get-Job | Remove-Job" -ForegroundColor Magenta
Write-Host "  To check job status: Get-Job" -ForegroundColor Magenta
Write-Host ""
Write-Host "⚡ Port forwarding is now running in background jobs!" -ForegroundColor Green
Write-Host "   Press Ctrl+C to stop this task (port forwarding will continue)" -ForegroundColor Cyan

# Keep the script running to maintain the display
try {
    while ($true) {
        Start-Sleep 5
        # Check if any jobs have failed and restart them
        $failedJobs = Get-Job | Where-Object { $_.State -eq "Failed" -and $_.Name -like "*-forward" }
        if ($failedJobs) {
            Write-Host "⚠️  Some port forwarding jobs failed, restarting..." -ForegroundColor Yellow
            foreach ($job in $failedJobs) {
                $job | Remove-Job
                $svc = $services | Where-Object { $_.Name -eq $job.Name }
                if ($svc) {
                    Start-Job -Name $svc.Name -ScriptBlock {
                        param($serviceName, $portMapping)
                        kubectl port-forward service/$serviceName $portMapping 2>$null
                    } -ArgumentList $svc.Service, $svc.Port | Out-Null
                }
            }
        }
    }
}
catch {
    Write-Host ""
    Write-Host "🛑 Port forwarding task stopped" -ForegroundColor Yellow
    Write-Host "   Background jobs are still running. Use 'Get-Job | Stop-Job; Get-Job | Remove-Job' to stop them." -ForegroundColor Cyan
}
