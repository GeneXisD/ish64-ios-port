#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ish64 iOS build helper
# - cleans build dir
# - patches common Apple-header collisions + errno includes
# - regenerates CMake/Xcode build
# - runs xcodebuild for target ishcore (and/or full app)
# ============================================================

ROOT="${HOME}/Projects/ish64"
IOS_DIR="${ROOT}/ios"
BUILD_DIR="${IOS_DIR}/build-xcode"

XCODE_APP="/Applications/Xcode-beta-3.app"
SCHEME="ish64_ios"
CONFIG="Debug"
DEST="generic/platform=iOS"
TARGET="ishcore"   # change to "ish64_ios" if you want the app build target instead

log() { printf "\n\033[1m==>\033[0m %s\n" "$*"; }

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1" >&2; exit 1; }
}

backup_inplace() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  [[ -f "${f}.bak" ]] || cp -p "$f" "${f}.bak"
}

# --- Patch 1: fallthrough macro collision (CoreFoundation / dispatch)
patch_fallthrough_macro() {
  local misc_h="${ROOT}/misc.h"
  [[ -f "$misc_h" ]] || return 0

  if grep -qE '^[[:space:]]*#define[[:space:]]+fallthrough[[:space:]]+__attribute__\(\(fallthrough\)\)' "$misc_h"; then
    log "Patching misc.h: rename fallthrough -> ISH_FALLTHROUGH (and keep compatibility)"
    backup_inplace "$misc_h"

    # Replace the macro definition line
    # - define ISH_FALLTHROUGH
    # - optionally define fallthrough only if not already defined by system headers
    perl -0777 -i -pe '
      s/^[ \t]*#define[ \t]+fallthrough[ \t]+__attribute__\(\(fallthrough\)\)[ \t]*$/#define ISH_FALLTHROUGH __attribute__((fallthrough))\n#ifndef fallthrough\n#define fallthrough ISH_FALLTHROUGH\n#endif/m
    ' "$misc_h"
  else
    log "misc.h: no direct fallthrough macro definition found (skipping)"
  fi

  # Also harden ios/main.m so system headers get included before any project headers leak macros.
  local main_m="${IOS_DIR}/main.m"
  if [[ -f "$main_m" ]]; then
    # If main.m includes project headers before UIKit/Foundation, this can leak macros.
    # We'll ensure UIKit import stays first and undef fallthrough after system imports.
    log "Patching ios/main.m: ensure system headers first + undef fallthrough after UIKit/Foundation"
    backup_inplace "$main_m"

    # If there isn't an #undef fallthrough already, add one after UIKit import
    if ! grep -qE '^[[:space:]]*#undef[[:space:]]+fallthrough' "$main_m"; then
      perl -0777 -i -pe '
        s/(#import[ \t]+<UIKit\/UIKit\.h>[^\n]*\n)/$1\n#ifdef fallthrough\n#undef fallthrough\n#endif\n\n/s
      ' "$main_m"
    fi
  fi
}

# --- Patch 2: errno/E* missing in slirp sources
patch_slirp_errno() {
  local SLIRP_DIR="${ROOT}/emu/tinyemu/slirp"
  [[ -d "$SLIRP_DIR" ]] || return 0

  log "Patching slirp sources: add <errno.h> where needed"
  local files=(
    "tcp_input.c"
    "socket.c"
    "slirp.c"
  )

  for f in "${files[@]}"; do
    local path="${SLIRP_DIR}/${f}"
    [[ -f "$path" ]] || continue

    # Only patch if errno is referenced and errno.h not included
    if grep -q 'errno' "$path" && ! grep -qE '^[[:space:]]*#include[[:space:]]*<errno\.h>' "$path"; then
      backup_inplace "$path"

      # Insert after the first block of includes (after last initial #include line)
      perl -0777 -i -pe '
        if ($ARGV =~ /(tcp_input\.c|socket\.c|slirp\.c)$/) {
          s/(\A(?:[ \t]*#include[^\n]*\n)+)/$1#include <errno.h>\n/s
        }
      ' "$path"
    fi

    # slirp.c in your log shows a real syntax error: send(... 0, 0; missing ')'
    # We can’t reliably auto-fix without seeing your exact source line(s),
    # but we CAN flag it early and stop with a pointer.
  done
}

# --- Optional: detect obvious syntax issues that will still fail even after includes
sanity_scan() {
  log "Sanity scan for known hard failures"

  local slirp_c="${ROOT}/emu/tinyemu/slirp/slirp.c"
  if [[ -f "$slirp_c" ]]; then
    # Look for the exact broken "send(... 0, 0;" pattern that your log shows
    if grep -nE 'send\([^;]*, 0, 0;[[:space:]]*$' "$slirp_c" >/dev/null; then
      echo
      echo "ERROR: Found an obvious syntax error in slirp.c: a send(...) call missing a closing ')'."
      echo "Fix it in: $slirp_c"
      echo "Look for a line ending with: send(..., 0, 0;"
      echo "It should likely be: send(..., 0, 0);"
      exit 2
    fi
  fi
}

clean_build_dir() {
  log "Cleaning build dir: $BUILD_DIR"
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"
}

configure_cmake_xcode() {
  log "Configuring CMake (Xcode generator)"
  require cmake

  cd "$IOS_DIR"

  # If you have a specific toolchain file or iOS flags in your project,
  # CMakeLists.txt usually handles it. This keeps it minimal.
  cmake -S "$IOS_DIR" -B "$BUILD_DIR" -G Xcode
}

run_xcodebuild() {
  log "Building with xcodebuild (scheme=$SCHEME, target=$TARGET, config=$CONFIG)"
  require xcodebuild

  export DEVELOPER_DIR="${XCODE_APP}/Contents/Developer"

  cd "$BUILD_DIR"

  # tee logs to a file for later grepping
  local LOGFILE="${BUILD_DIR}/xcodebuild_${SCHEME}_${CONFIG}.log"

  xcodebuild \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -destination "$DEST" \
    -target "$TARGET" \
    | tee "$LOGFILE"
}

main() {
  log "ish64 iOS build script starting"
  log "ROOT=$ROOT"
  log "IOS_DIR=$IOS_DIR"
  log "BUILD_DIR=$BUILD_DIR"

  patch_fallthrough_macro
  patch_slirp_errno
  sanity_scan

  clean_build_dir
  configure_cmake_xcode
  run_xcodebuild

  log "Done."
  echo "If it still fails, open the log: ${BUILD_DIR}/xcodebuild_${SCHEME}_${CONFIG}.log"
}

main "$@"
