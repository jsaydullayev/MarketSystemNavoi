# =============================================================================
# Release Android App Bundle (.aab) build for Google Play.
#
# WHY THIS SCRIPT EXISTS:
#   The hidden SuperAdmin console only works when the binary is built with
#   --dart-define=SUPERADMIN_CONSOLE_SEGMENT=<value>. In RELEASE builds the
#   dev fallback in app_config.dart is ignored on purpose, so an .aab built
#   with a plain `flutter build appbundle` shows "Konsol sozlanmagan" and the
#   console 404s. This script always injects the segment so it can't be
#   forgotten.
#
#   The value lives in MarketSystem.Client/dart_defines/prod.json (gitignored)
#   and MUST match the production backend's SuperAdmin__ConsoleSegment (the
#   server's .env). Copy dart_defines/prod.example.json -> prod.json and fill
#   it in on a fresh checkout.
#
# USAGE (from repo root):
#   .\build_appbundle.ps1
# Output:
#   MarketSystem.Client/build/app/outputs/bundle/release/app-release.aab
# =============================================================================

$ErrorActionPreference = "Stop"

$clientDir = Join-Path $PSScriptRoot "MarketSystem.Client"
$defines   = "dart_defines/prod.json"

Set-Location $clientDir

if (-not (Test-Path $defines)) {
    Write-Error "Missing $defines. Copy dart_defines/prod.example.json to dart_defines/prod.json and set SUPERADMIN_CONSOLE_SEGMENT to the server's SuperAdmin__ConsoleSegment value."
}

# Fail loudly if the segment is still the placeholder.
$seg = (Get-Content $defines -Raw | ConvertFrom-Json).SUPERADMIN_CONSOLE_SEGMENT
if ([string]::IsNullOrWhiteSpace($seg) -or $seg -like "REPLACE_*") {
    Write-Error "SUPERADMIN_CONSOLE_SEGMENT in $defines is not set. Fill in the real value from the server .env."
}

Write-Host "Building release AAB with SuperAdmin console segment baked in..." -ForegroundColor Cyan
flutter pub get
flutter build appbundle --release --dart-define-from-file=$defines

$aab = "build/app/outputs/bundle/release/app-release.aab"
if (Test-Path $aab) {
    Write-Host "Done: $clientDir\$aab" -ForegroundColor Green
    Write-Host "Remember to bump version in pubspec.yaml before each Play upload." -ForegroundColor Yellow
} else {
    Write-Error "Build finished but $aab was not found."
}
