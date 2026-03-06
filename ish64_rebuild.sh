#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# ish64 iOS build "self-healing" script
# - fixes poisoned permissions in build dirs
# - forces DerivedData to a writable folder
# - optionally disables code signing
# - builds ishcore target only
# -----------------------------

ROOT="${ROOT:-$HOME/Projects/ish64}"
IOS_DIR="${IOS_DIR:-$ROOT/ios}"
BUILD_DIR="${BUILD_DIR:-$IOS_DIR/build-xcode}"

XCODEBUILD="${XCODEBUILD:-/Applications/Xcode-beta-3.app/Contents/Developer/usr/bin/xcodebuild}"

SCHEME="${SCHEME:-ish64_ios}"
TARGET="${TARGET:-ishcore}"
CONFIG="${CONFIG:-Debug}"
DEST="${DEST:-generic/platform=iOS}"

# Put DerivedData somewhere ALWAYS writable by the current user
LOCAL_DERIVED="${LOCAL_DERIVED:-$BUILD_DIR/DerivedData}"

# If you want signing disabled (recommended for CLI builds / CI)
DISABLE_SIGNING="${DISABLE_SIGNING:-1}"

log() { echo -e "\n==> $*"; }

die() { echo "ERROR: $*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "Missing required tool: $1"; }

need mkdir
need rm
need chmod
need chown
need id

log "ish64 iOS build script starting"
log "ROOT=$ROOT"
log "IOS_DIR=$IOS_DIR"
log "BUILD_DIR=$BUILD_DIR"
log "LOCAL_DERIVED=$LOCAL_DERIVED"
log "Using xcodebuild: $XCODEBUILD"

[[ -d "$ROOT" ]] || die "ROOT not found: $ROOT"
[[ -d "$IOS_DIR" ]] || die "IOS_DIR not found: $IOS_DIR"
[[ -x "$XCODEBUILD" ]] || die "xcodebuild not executable: $XCODEBUILD"

# --- Fix poisoned build metadata ---
log "Fixing ownership + permissions under BUILD_DIR (user=$(id -un))"

mkdir -p "$BUILD_DIR" "$LOCAL_DERIVED"

# If ANYTHING under BUILD_DIR is owned by root (often happens after a sudo build),
# take it back. This does NOT require sudo if you own it already; if not, it will fail
# and we print a clear message.
if ! chown -R "$(id -un)":"$(id -gn)" "$BUILD_DIR" 2>/dev/null; then
  log "WARN: Could not chown $BUILD_DIR (likely root-owned)."
  log "If you previously ran xcodebuild with sudo, run this ONCE:"
  echo "    sudo chown -R $(id -un):$(id -gn) \"$BUILD_DIR\""
fi

# Make build dir writable and traversable.
chmod -R u+rwX,go+rX "$BUILD_DIR" 2>/dev/null || true

log "Cleaning poisoned build metadata (XCBuildData, DerivedData in build dir)"
rm -rf "$BUILD_DIR/build/XCBuildData" || true
rm -rf "$LOCAL_DERIVED" || true
mkdir -p "$LOCAL_DERIVED"

log "Sanity check: create test XCBuildData directory"
TESTPATH="$BUILD_DIR/build/XCBuildData/_writetest_$(date +%s)"
mkdir -p "$TESTPATH" || die "BUILD_DIR still not writable: $TESTPATH"
rmdir "$TESTPATH" || true
log "OK: build dir is writable now."

# --- Build args ---
SIGNING_ARGS=()
if [[ "$DISABLE_SIGNING" == "1" ]]; then
  SIGNING_ARGS=(
    "CODE_SIGNING_ALLOWED=NO"
    "CODE_SIGNING_REQUIRED=NO"
    "CODE_SIGN_IDENTITY="
    "DEVELOPMENT_TEAM="
  )
fi

log "Running xcodebuild (scheme=$SCHEME config=$CONFIG target=$TARGET dest=$DEST)"
set -x
cd "$IOS_DIR"
"$XCODEBUILD" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "$DEST" \
  -target "$TARGET" \
  -derivedDataPath "$LOCAL_DERIVED" \
  "${SIGNING_ARGS[@]}" \
  build
set +x

log "Build finished."
