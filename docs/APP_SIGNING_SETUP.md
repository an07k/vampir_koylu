# App Signing Setup Guide

## Overview

This guide explains how to set up release signing for Google Play publishing. App signing is **required** to publish Android apps on Google Play Store.

## What Changed

We've configured `build.gradle.kts` to support release signing with the following features:

1. **Automatic keystore detection** - looks for `android/app/release.jks`
2. **Environment variable support** - for CI/CD pipelines
3. **ProGuard optimization** - for smaller, faster APKs
4. **Proper release build configuration** - minification and optimization enabled

## Quick Start

### Option 1: Using the Script (Recommended)

**Windows:**
```bash
cd scripts
.\generate-release-keystore.bat
```

**macOS/Linux:**
```bash
bash scripts/generate-release-keystore.sh
```

### Option 2: Manual Generation

If keytool is available, run:

```bash
keytool -genkey -v \
    -keystore android/app/release.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias vampir_koylu \
    -storepass "VampirKoylu2024!" \
    -keypass "VampirKoylu2024!" \
    -dname "CN=Vampir Koylu,O=Games,L=Istanbul,ST=Istanbul,C=TR"
```

## Building Release APK

Once the keystore is set up:

```bash
flutter build apk --release
```

This will create: `build/app/outputs/apk/release/app-release.apk`

## Environment Variables (CI/CD)

For automated builds, set these environment variables:

```bash
export VAMPIR_KEYSTORE_PATH="$(pwd)/android/app/release.jks"
export VAMPIR_KEYSTORE_PASSWORD="VampirKoylu2024!"
export VAMPIR_KEY_PASSWORD="VampirKoylu2024!"
export VAMPIR_KEY_ALIAS="vampir_koylu"
```

### GitHub Actions Example

```yaml
- name: Build Release APK
  env:
    VAMPIR_KEYSTORE_PATH: ${{ github.workspace }}/android/app/release.jks
    VAMPIR_KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    VAMPIR_KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
    VAMPIR_KEY_ALIAS: vampir_koylu
  run: flutter build apk --release
```

## Security Best Practices

⚠️ **IMPORTANT**: The keystore file contains signing credentials. Treat it like a password:

1. **Never commit to git** - `*.jks` is in `.gitignore` ✓
2. **Store securely** - Use password managers or secure vaults
3. **Backup** - Keep a secure backup of the keystore
4. **Rotate credentials** - Change passwords periodically
5. **CI/CD secrets** - Store passwords as GitHub/GitLab secrets, NOT in code
6. **Team access** - Share keystore securely with authorized team members only

## Keystore Information

Current setup uses:

| Field | Value |
|-------|-------|
| **Keystore File** | `android/app/release.jks` |
| **Keystore Password** | `VampirKoylu2024!` |
| **Key Alias** | `vampir_koylu` |
| **Key Password** | `VampirKoylu2024!` |
| **Algorithm** | RSA 2048-bit |
| **Validity** | 10,000 days (~27 years) |
| **Organization** | Vampir Koylu Games |
| **Country** | TR (Turkey) |

## Troubleshooting

### "keytool: command not found"

**Solution:** Install Java Development Kit (JDK)

- **Windows**: Download from [oracle.com/java/technologies/downloads](https://www.oracle.com/java/technologies/downloads/)
- **macOS**: `brew install openjdk`
- **Linux (Ubuntu)**: `sudo apt install openjdk-17-jdk`

### Build fails with "Keystore not found"

Make sure the keystore exists at `android/app/release.jks`:

```bash
ls -la android/app/release.jks
```

If missing, run the generation script again.

### "Keystore was tampered with, or password was incorrect"

Check that passwords match environment variables:

```bash
# Verify manually
keytool -list -v -keystore android/app/release.jks -storepass "VampirKoylu2024!"
```

## Build Output

After successful build, you'll see:

```
✅ Built build/app/outputs/apk/release/app-release.apk (XX.X MB)
```

This APK is ready to upload to Google Play Console!

## Next Steps

1. ✅ Keystore created
2. ⬜ Update `android/app/AndroidManifest.xml` with proper app permissions
3. ⬜ Change `applicationId` from `com.example.vampir_koylu` to your package name
4. ⬜ Test release build on real device
5. ⬜ Upload to Google Play Console

## References

- [Android App Signing Guide](https://developer.android.com/studio/publish/app-signing)
- [Google Play Publishing](https://play.google.com/console)
- [Flutter Build Release Guide](https://flutter.dev/docs/deployment/android#building-an-aab)
- [ProGuard Configuration](https://developer.android.com/studio/build/shrink-code)
