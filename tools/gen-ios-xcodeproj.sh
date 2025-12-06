#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"
BUILD_DIR="$IOS_DIR/build-xcode"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Generating Xcode project for iOS..."
cmake -G Xcode "$IOS_DIR"

echo
echo "Xcode project generated at:"
echo "  $BUILD_DIR/ish64_ios.xcodeproj"
echo
echo "Opening in Xcode..."
open "ish64_ios.xcodeproj"
