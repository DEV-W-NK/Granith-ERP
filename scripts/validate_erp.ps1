[CmdletBinding()]
param(
  [switch]$SkipTests,
  [switch]$BuildWeb
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $root

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Action
  )

  Write-Host ""
  Write-Host "==> $Name" -ForegroundColor Cyan
  & $Action
}

Invoke-Step 'flutter pub get' { flutter pub get }
Invoke-Step 'dart analyze' { dart analyze }

if (-not $SkipTests) {
  Invoke-Step 'flutter test' { flutter test }
}

if ($BuildWeb) {
  Invoke-Step 'flutter build web --release' { flutter build web --release }
}
