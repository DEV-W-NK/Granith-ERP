param(
  [string]$Device = "chrome",
  [string]$EnvFile = ".env.local",
  [switch]$CheckOnly,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root $EnvFile
$allowedKeys = @(
  "SUPABASE_URL",
  "SUPABASE_PUBLISHABLE_KEY",
  "GEMINI_API_KEY",
  "GEMINI_MODEL",
  "GOOGLE_MAPS_API_KEY",
  "GOOGLE_OAUTH_WEB_CLIENT_ID",
  "GOOGLE_OAUTH_ANDROID_CLIENT_ID",
  "GOOGLE_OAUTH_IOS_CLIENT_ID",
  "GOOGLE_OAUTH_CLIENT_SECRET",
  "GOOGLE_OAUTH_REDIRECT_URL"
)
$dartDefineKeys = @(
  "SUPABASE_URL",
  "SUPABASE_PUBLISHABLE_KEY",
  "GEMINI_API_KEY",
  "GEMINI_MODEL",
  "GOOGLE_MAPS_API_KEY"
)
$values = @{}

if (Test-Path $envPath) {
  foreach ($line in Get-Content -LiteralPath $envPath) {
    if ($line -match '^\s*#' -or $line.Trim().Length -eq 0) {
      continue
    }

    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
      $key = $Matches[1]
      $value = $Matches[2].Trim()
      if (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
      ) {
        $value = $value.Substring(1, $value.Length - 2)
      }

      if ($allowedKeys -contains $key) {
        $values[$key] = $value
      }
    }
  }
}

foreach ($key in $allowedKeys) {
  if (-not $values.ContainsKey($key) -and [Environment]::GetEnvironmentVariable($key)) {
    $values[$key] = [Environment]::GetEnvironmentVariable($key)
  }
}

$webEnvPath = Join-Path $root "web\env.js"
$mapsKey = if ($values.ContainsKey("GOOGLE_MAPS_API_KEY")) { $values["GOOGLE_MAPS_API_KEY"] } else { "" }
$mapsKeyJson = $mapsKey | ConvertTo-Json -Compress
Set-Content -LiteralPath $webEnvPath -Encoding UTF8 -Value @"
window.GRANITH_ENV = {
  GOOGLE_MAPS_API_KEY: $mapsKeyJson
};
"@

$iosSecretsPath = Join-Path $root "ios\Flutter\Secrets.xcconfig"
Set-Content -LiteralPath $iosSecretsPath -Encoding UTF8 -Value "GOOGLE_MAPS_API_KEY=$mapsKey"

$dartDefines = @()
foreach ($key in $dartDefineKeys) {
  if ($values.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace($values[$key])) {
    $dartDefines += "--dart-define=$key=$($values[$key])"
  }
}

$setupGroups = @(
  @{ Name = "Gemini"; Keys = @("GEMINI_API_KEY") },
  @{ Name = "Google Maps"; Keys = @("GOOGLE_MAPS_API_KEY") },
  @{ Name = "Google OAuth"; Keys = @("GOOGLE_OAUTH_WEB_CLIENT_ID", "GOOGLE_OAUTH_CLIENT_SECRET") }
)
foreach ($group in $setupGroups) {
  $missing = @()
  foreach ($key in $group.Keys) {
    if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
      $missing += $key
    }
  }

  if ($missing.Count -gt 0) {
    Write-Warning "$($group.Name) incompleto em ${EnvFile}: $($missing -join ', ')"
  }
}

$loadedKeys =
  ($values.GetEnumerator() |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_.Value) } |
    ForEach-Object { $_.Key } |
    Sort-Object) -join ", "
if ([string]::IsNullOrWhiteSpace($loadedKeys)) {
  Write-Host "Nenhuma chave carregada. Crie .env.local a partir de .env.example."
} else {
  Write-Host "Chaves carregadas para desenvolvimento: $loadedKeys"
}

if ($CheckOnly) {
  Write-Host "CheckOnly ativo: arquivos locais gerados, Flutter nao foi iniciado."
  exit 0
}

& flutter run -d $Device @dartDefines @FlutterArgs
exit $LASTEXITCODE
