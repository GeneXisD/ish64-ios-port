#!/usr/bin/env bash
set -euo pipefail

ROOT="${HOME}/Projects/ish64"
SLIRP_C="${ROOT}/emu/tinyemu/slirp/slirp.c"
BUILD_SCRIPT="${ROOT}/ios/build_ish64_ios.sh"

log() { printf "\n\033[1m==>\033[0m %s\n" "$*"; }

backup_once() {
  local f="$1"
  [[ -f "$f" ]] || { echo "Missing file: $f" >&2; exit 1; }
  [[ -f "${f}.bak" ]] || cp -p "$f" "${f}.bak"
}

fix_send_missing_paren() {
  log "Fixing send(...) missing closing ')' in: $SLIRP_C"
  backup_once "$SLIRP_C"

  # Replace ONLY a send(...) call that ends with ", 0, 0;" at end-of-line.
  # This matches your compiler error and avoids touching other send() calls.
  perl -i -pe '
    s/\bsend\(([^;]*?),\s*0\s*,\s*0\s*;\s*$/send($1, 0, 0);/;
  ' "$SLIRP_C"

  # Verify fix: no remaining broken lines
  if grep -nE 'send\([^;]*,\s*0\s*,\s*0\s*;[[:space:]]*$' "$SLIRP_C" >/dev/null; then
    echo "ERROR: The broken send(..., 0, 0; pattern still exists in $SLIRP_C" >&2
    echo "Open the file and search for: send(" >&2
    exit 2
  fi

  log "Verified: no remaining send(..., 0, 0; lines"
}

main() {
  fix_send_missing_paren

  log "Running build script: $BUILD_SCRIPT"
  if [[ ! -x "$BUILD_SCRIPT" ]]; then
    echo "ERROR: Build script not found or not executable: $BUILD_SCRIPT" >&2
    echo "Make sure build_ish64_ios.sh exists and chmod +x it." >&2
    exit 3
  fi

  "$BUILD_SCRIPT"
}

main "$@"
