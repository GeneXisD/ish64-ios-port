#!/usr/bin/env bash
# build_ish64_ios.sh
# Victor: one-shot “patch + build” driver for your ish64 iOS Xcode build.
# - Idempotently patches missing errno symbols in slirp/sock sources
# - Runs xcodebuild with your Xcode-beta toolchain
# - Saves a full build log + a small error/warning summary

set -euo pipefail

# -----------------------------
# Config (edit if you want)
# -----------------------------
XCODE_APP_DEFAULT="/Applications/Xcode-beta-3.app"
PROJECT_REL="ios/build-xcode/ish64_ios.xcodeproj"
SCHEME_DEFAULT="ish64_ios"
CONFIG_DEFAULT="Debug"
SDK_DEFAULT="iphoneos"
DEST_DEFAULT="generic/platform=iOS"
LOG_DIR_DEFAULT="ios/build-logs"

# -----------------------------
# Helpers
# -----------------------------
say() { printf "\n==> %s\n" "$*"; }

repo_root() {
  # repo root = parent of this script's directory (works if you place script anywhere inside repo too)
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # walk up until we see "ios" folder
  local d="$here"
  while [[ "$d" != "/" ]]; do
    if [[ -d "$d/ios" ]]; then
      echo "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done
  echo "ERROR: Could not locate repo root (expected an 'ios' dir up the tree)." >&2
  exit 1
}

insert_include_if_missing() {
  local file="$1"
  local include_line="$2"   # e.g. '#include <errno.h>'
  local marker_regex="$3"   # insert after the last include matching this regex, else at top

  [[ -f "$file" ]] || { echo "WARN: missing file: $file" >&2; return 0; }

  # already present?
  if grep -qF "$include_line" "$file"; then
    return 0
  fi

  # Insert after last matching include marker, else at top.
  # Uses perl for portable in-place editing on macOS.
  perl -0777 -i -pe '
    my ($inc, $re) = @ARGV;
    if (index($_, $inc) >= 0) { print STDERR "already had include\n"; exit 0; }
    if (m/('"$marker_regex"')/s) {
      # find position after the last match of marker_regex
      my $pos = 0;
      while (m/('"$marker_regex"')/sg) { $pos = pos($_); }
      substr($_, $pos, 0) = "\n$inc";
    } else {
      $_ = "$inc\n" . $_;
    }
  ' -- "$include_line" "$marker_regex" "$file"
}

patch_errno_symbols() {
  local root="$1"

  say "Applying idempotent errno/strerror include patches (if needed)"

  # Files from your log that error on errno/EINTR/EAGAIN/EINVAL/EINPROGRESS/EWOULDBLOCK
  local tcp_input="$root/emu/tinyemu/slirp/tcp_input.c"
  local socket_c="$root/emu/tinyemu/slirp/socket.c"
  local sock_c="$root/fs/sock.c"

  # Insert after the last existing include line. Marker matches "#include ..." lines.
  local marker='^#include[[:space:]]+.*$'

  # errno + constants
  insert_include_if_missing "$tcp_input" '#include <errno.h>' "$marker"
  insert_include_if_missing "$socket_c"  '#include <errno.h>' "$marker"
  insert_include_if_missing "$sock_c"    '#include <errno.h>' "$marker"

  # strerror lives in string.h (often already included, but make sure)
  insert_include_if_missing "$tcp_input" '#include <string.h>' "$marker"
  insert_include_if_missing "$socket_c"  '#include <string.h>' "$marker"
  insert_include_if_missing "$sock_c"    '#include <string.h>' "$marker"

  say "Patch step complete"
}

run_build() {
  local root="$1"
  local xcode_app="$2"
  local scheme="$3"
  local config="$4"
  local sdk="$5"
  local destination="$6"
  local log_dir="$7"

  local project="$root/$PROJECT_REL"
  [[ -d "$project" ]] || { echo "ERROR: Xcode project not found: $project" >&2; exit 1; }

  mkdir -p "$root/$log_dir"

  local ts
  ts="$(date +"%Y%m%d-%H%M%S")"
  local log="$root/$log_dir/build-$scheme-$config-$sdk-$ts.log"

  say "Using Xcode: $xcode_app"
  [[ -d "$xcode_app" ]] || { echo "ERROR: Xcode app not found: $xcode_app" >&2; exit 1; }

  export DEVELOPER_DIR="$xcode_app/Contents/Developer"

  say "Running xcodebuild → logging to: $log"
  set +e
  xcodebuild \
    -project "$project" \
    -scheme "$scheme" \
    -configuration "$config" \
    -sdk "$sdk" \
    -destination "$destination" \
    build \
    2>&1 | tee "$log"
  local status="${PIPESTATUS[0]}"
  set -e

  say "Build finished with status: $status"

  say "Quick summary (errors + warnings)"
  # errors
  grep -nE " error: " "$log" | tail -n 40 || true
  # warnings
  grep -nE " warning: " "$log" | tail -n 40 || true

  if [[ "$status" -ne 0 ]]; then
    echo
    echo "BUILD FAILED (exit $status). Full log:"
    echo "  $log"
    echo
    echo "Outside-the-box tip:"
    echo "  If you keep seeing ZERO_CHECK run every time, open the Xcode project"
    echo "  and check 'Based on dependency analysis' in the ZERO_CHECK build phase."
    exit "$status"
  fi

  say "BUILD SUCCEEDED ✅"
  echo "Log saved at: $log"
}

# -----------------------------
# Main
# -----------------------------
ROOT="$(repo_root)"

XCODE_APP="${XCODE_APP:-$XCODE_APP_DEFAULT}"
SCHEME="${SCHEME:-$SCHEME_DEFAULT}"
CONFIG="${CONFIG:-$CONFIG_DEFAULT}"
SDK="${SDK:-$SDK_DEFAULT}"
DESTINATION="${DESTINATION:-$DEST_DEFAULT}"
LOG_DIR="${LOG_DIR:-$LOG_DIR_DEFAULT}"

patch_errno_symbols "$ROOT"
run_build "$ROOT" "$XCODE_APP" "$SCHEME" "$CONFIG" "$SDK" "$DESTINATION" "$LOG_DIR"
