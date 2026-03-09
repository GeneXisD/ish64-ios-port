#!/usr/bin/env bash
set -euo pipefail
xcodebuild \
  -project iSH.xcodeproj \
  -scheme iSH \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  clean build
