#!/usr/bin/env pwsh

Write-Host "🔧 Android SDK Flutter Config Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# SDK path
$sdkPath = "C:/Program Files/Unity/Hub/Editor/6000.0.37f1/Editor/Data/PlaybackEngines/AndroidPlayer/SDK"

Write-Host "Setting Android SDK path..." -ForegroundColor Yellow
Write-Host "Path: $sdkPath" -ForegroundColor Gray
Write-Host ""

# Configure Flutter
flutter config --android-sdk-path=$sdkPath

Write-Host ""
Write-Host "✅ Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Running flutter doctor..." -ForegroundColor Cyan
Write-Host ""

flutter doctor
