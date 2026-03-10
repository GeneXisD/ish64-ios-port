#!/usr/bin/env bash

set -e

echo "[ish64] Fast development build starting..."

xcodebuild \
-project iSH.xcodeproj \
-scheme iSH \
-configuration Debug \
-destination 'platform=iOS Simulator,name=iPhone 16' \
CODE_SIGNING_ALLOWED=NO \
build

echo "[ish64] Build finished."
