#!/bin/bash
set -e

APP_NAME="Hush"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

echo "🚀 Building Hush for Release (ARM64)..."
swift build -c release --arch arm64

echo "📦 Creating App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy Binary
cp ".build/arm64-apple-macosx/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "Hush/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# (Optional) Copy Resources/Models if we wanted to bundle them
# cp -r Resources/* "$APP_BUNDLE/Contents/Resources/"

echo "💿 Creating DMG..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_NAME"

echo "✅ Done! Created $DMG_NAME"
