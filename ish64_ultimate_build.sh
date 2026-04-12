#!/bin/bash
# ish64_ultimate_build.sh
# Fully automated build + patch + export pipeline for iSH

set -euo pipefail

# ---------- CONFIG ----------
PROJECT_DIR="$HOME/Projects/ish64"
BUILD_DIR="$PROJECT_DIR/build"
DEPLOYMENT_TARGET="12.0"
BUILD_TYPE="${1:-Debug}"   # Default Debug; pass "Release" for TestFlight
EXPORT_DIR="$BUILD_DIR/export"
IPA_NAME="iSH.ipa"

# ---------- 1️⃣ Detect Xcode ----------
XCODE_PATH=$(xcode-select -p)
echo "🔧 Using Xcode at $XCODE_PATH"

# Find xcodebuild binary safely
if [ -x "$XCODE_PATH/usr/bin/xcodebuild" ]; then
    XCODEBUILD="$XCODE_PATH/usr/bin/xcodebuild"
else
    XCODEBUILD=$(which xcodebuild)
fi

# Get Xcode version (robust, avoids head issues)
XCODE_VERSION=$("$XCODEBUILD" -version 2>/dev/null | awk 'NR==1{print}')
echo "🧾 Xcode version: $XCODE_VERSION"
# ---------- 2️⃣ Detect latest simulator ----------
SIMULATOR_NAME=$(xcrun simctl list devices available | grep -m1 'iPhone' | sed 's/ (.*//')
echo "📱 Using simulator: $SIMULATOR_NAME"

# ---------- 3️⃣ Clean DerivedData + build ----------
echo "🧹 Cleaning old builds..."
rm -rf ~/Library/Developer/Xcode/DerivedData/iSH-*
rm -rf "$BUILD_DIR"

# ---------- 4️⃣ Patch legacy code ----------
echo "🛠 Patching libarchive and dependencies..."
LIBARCHIVE="$PROJECT_DIR/deps/libarchive/libarchive/archive_write_open_file.c"
if ! grep -q "O_BINARY" "$LIBARCHIVE"; then
    sed -i '' '1i\
#ifndef O_BINARY\n#define O_BINARY 0\n#endif
' "$LIBARCHIVE"
fi

# ---------- 5️⃣ Set deployment target for all targets ----------
echo "📌 Setting deployment target to $DEPLOYMENT_TARGET for all Xcode targets..."
PBXPROJ="$PROJECT_DIR/iSH.xcodeproj/project.pbxproj"
if ! grep -q "$DEPLOYMENT_TARGET" "$PBXPROJ"; then
    sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = [0-9]\{2\}\(\.[0-9]\)\?/IPHONEOS_DEPLOYMENT_TARGET = $DEPLOYMENT_TARGET/g" "$PBXPROJ"
fi

# ---------- 6️⃣ Meson + Ninja build ----------
echo "⚙️ Running Meson + Ninja..."
cd "$PROJECT_DIR"
meson setup build --wipe || meson setup build
ninja -C build

# ---------- 7️⃣ Xcode build ----------
echo "🏗 Building iSH via Xcode..."
xcodebuild \
  -project "$PROJECT_DIR/iSH.xcodeproj" \
  -scheme iSH \
  -configuration "$BUILD_TYPE" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  CODE_SIGNING_ALLOWED=NO

# ---------- 8️⃣ TestFlight / Release export ----------
if [ "$BUILD_TYPE" = "Release" ]; then
    echo "📦 Archiving for TestFlight..."
    mkdir -p "$EXPORT_DIR"
    ARCHIVE_PATH="$BUILD_DIR/iSH.xcarchive"
    xcodebuild \
      -project "$PROJECT_DIR/iSH.xcodeproj" \
      -scheme iSH \
      -configuration Release \
      -destination 'generic/platform=iOS' \
      archive \
      -archivePath "$ARCHIVE_PATH"

    # Generate ExportOptions.plist dynamically
    PLIST_PATH="$BUILD_DIR/ExportOptions.plist"
    cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

    echo "📤 Exporting IPA..."
    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportOptionsPlist "$PLIST_PATH" \
      -exportPath "$EXPORT_DIR"

    echo "✅ IPA exported to $EXPORT_DIR/$IPA_NAME"
fi

echo "🎉 Build pipeline completed successfully!"
