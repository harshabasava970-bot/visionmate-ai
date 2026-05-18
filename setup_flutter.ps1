# VisionMate AI - Flutter Setup Script
# Run this script AFTER flutter_sdk.zip finishes downloading
# Usage: .\setup_flutter.ps1

$ErrorActionPreference = "Stop"
$flutterZip = "$env:USERPROFILE\flutter_sdk.zip"
$flutterDir = "C:\flutter"

Write-Host "=== VisionMate AI - Flutter Setup ===" -ForegroundColor Cyan

# 1. Check zip exists
if (-not (Test-Path $flutterZip)) {
    Write-Host "ERROR: $flutterZip not found. Download it first." -ForegroundColor Red
    exit 1
}

$sizeMB = [math]::Round((Get-Item $flutterZip).Length / 1MB, 1)
Write-Host "Flutter zip found: $sizeMB MB" -ForegroundColor Green

# 2. Extract to C:\flutter
Write-Host "Extracting Flutter SDK to $flutterDir ..." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'
Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
Write-Host "Extraction complete." -ForegroundColor Green

# 3. Add to PATH for this session
$env:PATH = "C:\flutter\bin;$env:PATH"
Write-Host "Flutter added to PATH for this session." -ForegroundColor Green

# 4. Add to user PATH permanently
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*C:\flutter\bin*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "C:\flutter\bin;$userPath", "User")
    Write-Host "Flutter added to user PATH permanently." -ForegroundColor Green
} else {
    Write-Host "Flutter already in user PATH." -ForegroundColor Yellow
}

# 5. Verify flutter
Write-Host "Verifying Flutter installation..." -ForegroundColor Yellow
flutter --version

# 6. Run flutter pub get
Write-Host "Running flutter pub get..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\frontend"
flutter pub get

Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host "Backend: http://localhost:8000 (already running)" -ForegroundColor Green
Write-Host "To run the app: flutter run" -ForegroundColor Green
Write-Host "To build APK: flutter build apk --release" -ForegroundColor Green
