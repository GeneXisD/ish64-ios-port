#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/meson-build"
APP_DIR="$PROJECT_ROOT/dist/macos/iSH64.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

if [ ! -x "$BUILD_DIR/ish" ]; then
    echo "ERROR: $BUILD_DIR/ish not found or not executable."
    echo "Build it first with:  meson setup meson-build && ninja -C meson-build"
    exit 1
fi

echo "Creating app bundle at: $APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

echo "Copying ish binary..."
cp "$BUILD_DIR/ish" "$MACOS/ish"
chmod +x "$MACOS/ish"

echo "Writing Info.plist..."
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>iSH64</string>
    <key>CFBundleDisplayName</key>
    <string>iSH64</string>
    <key>CFBundleIdentifier</key>
    <string>net.ritualmesh.ish64</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>ish</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSBackgroundOnly</key>
    <false/>
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Done."
echo "App created at: $APP_DIR"
echo "You can run it with: open \"$APP_DIR\""
