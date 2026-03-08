@echo off
REM Generate Release Keystore for Vampir Köylü (Windows)
REM This script creates a release.jks keystore for signing APKs

setlocal enabledelayedexpansion

set KEYSTORE_PATH=android\app\release.jks
set ALIAS=vampir_koylu
set KEYSTORE_PASSWORD=VampirKoylu2024!
set KEY_PASSWORD=VampirKoylu2024!
set VALIDITY_DAYS=10000

echo.
echo 🔐 Generating Release Keystore for Vampir Köylü
echo ================================================
echo.
echo Keystore Path: %KEYSTORE_PATH%
echo Alias: %ALIAS%
echo Validity: %VALIDITY_DAYS% days
echo.

if exist "%KEYSTORE_PATH%" (
    echo ⚠️  Keystore already exists at %KEYSTORE_PATH%
    echo    Backup the existing keystore before regenerating!
    echo.
    set /p CONTINUE="Continue? (y/n): "
    if /i not "!CONTINUE!"=="y" (
        echo Cancelled.
        exit /b 1
    )
)

REM Check if keytool is available
where keytool >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ keytool not found!
    echo    Please ensure Java Development Kit (JDK) is installed and in your PATH
    echo    Download from: https://www.oracle.com/java/technologies/downloads/
    exit /b 1
)

echo Generating keystore...
keytool -genkey -v ^
    -keystore "%KEYSTORE_PATH%" ^
    -keyalg RSA ^
    -keysize 2048 ^
    -validity %VALIDITY_DAYS% ^
    -alias "%ALIAS%" ^
    -storepass "%KEYSTORE_PASSWORD%" ^
    -keypass "%KEY_PASSWORD%" ^
    -dname "CN=Vampir Koylu,O=Games,L=Istanbul,ST=Istanbul,C=TR"

if %errorlevel% equ 0 (
    echo.
    echo ✅ Keystore generated successfully!
    echo.
    echo 📝 Store these credentials securely:
    echo    Keystore File: %KEYSTORE_PATH%
    echo    Keystore Password: %KEYSTORE_PASSWORD%
    echo    Key Alias: %ALIAS%
    echo    Key Password: %KEY_PASSWORD%
    echo.
    echo 💾 Environment variables (for CI/CD in PowerShell):
    echo    $env:VAMPIR_KEYSTORE_PATH = '%CD%\%KEYSTORE_PATH%'
    echo    $env:VAMPIR_KEYSTORE_PASSWORD = '%KEYSTORE_PASSWORD%'
    echo    $env:VAMPIR_KEY_PASSWORD = '%KEY_PASSWORD%'
    echo    $env:VAMPIR_KEY_ALIAS = '%ALIAS%'
    echo.
    echo ⚠️  IMPORTANT: release.jks is already in .gitignore
    echo    Verify it won't be committed: git status
    echo.
) else (
    echo.
    echo ❌ Failed to generate keystore
    exit /b 1
)

endlocal
