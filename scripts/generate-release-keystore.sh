#!/bin/bash

# Generate Release Keystore for Vampir Köylü
# This script creates a release.jks keystore for signing APKs

set -e

KEYSTORE_PATH="android/app/release.jks"
ALIAS="vampir_koylu"
KEYSTORE_PASSWORD="${VAMPIR_KEYSTORE_PASSWORD:-VampirKoylu2024!}"
KEY_PASSWORD="${VAMPIR_KEY_PASSWORD:-VampirKoylu2024!}"
VALIDITY_DAYS=10000

echo "🔐 Generating Release Keystore for Vampir Köylü"
echo "================================================"
echo ""
echo "Keystore Path: $KEYSTORE_PATH"
echo "Alias: $ALIAS"
echo "Validity: $VALIDITY_DAYS days"
echo ""

if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Keystore already exists at $KEYSTORE_PATH"
    echo "   Backup the existing keystore before regenerating!"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ keytool not found!"
    echo "   Please ensure Java is installed and in your PATH"
    exit 1
fi

echo "Generating keystore..."
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -alias "$ALIAS" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Vampir Koylu,O=Games,L=Istanbul,ST=Istanbul,C=TR"

echo ""
echo "✅ Keystore generated successfully!"
echo ""
echo "📝 Store these credentials securely:"
echo "   Keystore File: $KEYSTORE_PATH"
echo "   Keystore Password: $KEYSTORE_PASSWORD"
echo "   Key Alias: $ALIAS"
echo "   Key Password: $KEY_PASSWORD"
echo ""
echo "💾 Environment variables (for CI/CD):"
echo "   export VAMPIR_KEYSTORE_PATH='$(pwd)/$KEYSTORE_PATH'"
echo "   export VAMPIR_KEYSTORE_PASSWORD='$KEYSTORE_PASSWORD'"
echo "   export VAMPIR_KEY_PASSWORD='$KEY_PASSWORD'"
echo "   export VAMPIR_KEY_ALIAS='$ALIAS'"
echo ""
echo "⚠️  IMPORTANT: Add release.jks to .gitignore!"
echo "   It's already in .gitignore, but verify it's there:"
echo "   grep 'release.jks' .gitignore"
echo ""
