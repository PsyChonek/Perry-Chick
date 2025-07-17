#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Generates secure random secrets for Strapi configuration
.DESCRIPTION
    This script generates secure random base64 encoded secrets for Strapi
    and updates the .env.local file with the generated values.
#>

param(
	[string]$EnvFile = ".env.local",
	[switch]$Force = $false
)

Write-Host "🔐 Generating Strapi secrets..." -ForegroundColor Green

function New-Base64Secret {
	param([int]$Length = 32)
	$bytes = New-Object byte[] $Length
	$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
	$rng.GetBytes($bytes)
	$rng.Dispose()
	return [Convert]::ToBase64String($bytes)
}

function New-AppKeys {
	$keys = @()
	for ($i = 0; $i -lt 4; $i++) {
		$keys += New-Base64Secret
	}
	return $keys -join ","
}

if (!(Test-Path $EnvFile)) {
	Write-Host "❌ Error: $EnvFile not found!" -ForegroundColor Red
	exit 1
}

$envContent = Get-Content $EnvFile

# Generate new secrets
$secrets = @{
	"STRAPI_JWT_SECRET"          = New-Base64Secret
	"STRAPI_ADMIN_JWT_SECRET"    = New-Base64Secret
	"STRAPI_APP_KEYS"            = New-AppKeys
	"STRAPI_API_TOKEN_SALT"      = New-Base64Secret
	"STRAPI_TRANSFER_TOKEN_SALT" = New-Base64Secret
}

Write-Host "🔑 Generated secrets:" -ForegroundColor Cyan
foreach ($key in $secrets.Keys) {
	$maskedValue = $secrets[$key].Substring(0, [Math]::Min(8, $secrets[$key].Length)) + "..."
	Write-Host "  $key = $maskedValue" -ForegroundColor Gray
}

# Update the .env file
$updatedContent = @()
foreach ($line in $envContent) {
	$updated = $false
	foreach ($secretKey in $secrets.Keys) {
		if ($line -match "^$secretKey=.*_change_me.*$" -or ($Force -and $line -match "^$secretKey=.*$")) {
			$updatedContent += "$secretKey=$($secrets[$secretKey])"
			$updated = $true
			Write-Host "  ✓ Updated $secretKey" -ForegroundColor Green
			break
		}
	}
	if (-not $updated) {
		$updatedContent += $line
	}
}

# Write back to file
$updatedContent | Set-Content $EnvFile -Encoding UTF8

Write-Host ""
Write-Host "✅ Strapi secrets generated and updated in $EnvFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the updated .env.local file" -ForegroundColor Cyan
Write-Host "  2. Run: ./scripts/update-env-config.ps1 -Apply -Restart" -ForegroundColor Cyan
Write-Host "  3. Or run: ./scripts/deploy-full.ps1" -ForegroundColor Cyan
