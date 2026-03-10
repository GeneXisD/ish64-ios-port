#!/usr/bin/env bash

set -e

echo "[ish64] Cleaning build environment..."

rm -rf ~/Library/Developer/Xcode/DerivedData/iSH*
rm -rf ios/build-xcode
rm -rf build

echo "[ish64] Starting full rebuild..."

xcodebuild \
-project iSH.xcodeproj \
-scheme iSH \
-configuration Debug \
-destination 'platform=iOS Simulator,name=iPhone 16' \
CODE_SIGNING_ALLOWED=NO \
clean build

echo "[ish64] Clean build finished."
