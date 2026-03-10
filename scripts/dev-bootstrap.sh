#!/usr/bin/env bash
set -e

echo "===================================="
echo " ish64 bootstrap starting"
echo "===================================="

# check required tools
REQUIRED=("git" "python3" "meson" "ninja" "xcodebuild")

for tool in "${REQUIRED[@]}"; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "[error] missing dependency: $tool"
        exit 1
    fi
done

echo "[ok] toolchain verified"

echo "------------------------------------"
echo "Initializing submodules"
echo "------------------------------------"

git submodule update --init --recursive

echo "[ok] submodules initialized"

echo "------------------------------------"
echo "Running project repair scripts"
echo "------------------------------------"

if [ -f scripts/patch-libarchive-pbx.py ]; then
    echo "patching libarchive project references"
    python3 scripts/patch-libarchive-pbx.py || true
fi

if [ -f scripts/check-pbx-missing-files.py ]; then
    echo "checking for missing Xcode project files"
    python3 scripts/check-pbx-missing-files.py || true
fi

echo "[ok] repair checks completed"

echo "------------------------------------"
echo "Cleaning Xcode derived data"
echo "------------------------------------"

rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo "[ok] cache cleaned"

echo "------------------------------------"
echo "Starting build"
echo "------------------------------------"

xcodebuild \
  -project iSH.xcodeproj \
  -scheme iSH \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  clean build

echo "===================================="
echo " ish64 bootstrap completed"
echo "===================================="
