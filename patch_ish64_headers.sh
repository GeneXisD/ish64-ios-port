#!/usr/bin/env bash
set -euo pipefail

# patch_ish64_headers.sh
# Idempotently adds missing system includes to fix undeclared sig*/errno/E* errors.

ROOT="${1:-.}"

file_exists() {
  [[ -f "$1" ]]
}

python_patch() {
  /usr/bin/env python3 - "$@" <<'PY'
import io, os, re, sys
from pathlib import Path

path = Path(sys.argv[1])
rules = sys.argv[2:]

text = path.read_text(encoding="utf-8", errors="replace")
orig = text

def has_include(h: str) -> bool:
  # Match: #include <h> or #include "h"
  return re.search(r'^\s*#\s*include\s*[<"]' + re.escape(h) + r'[>"]\s*$', text, re.M) is not None

def first_include_index(lines):
  for i, line in enumerate(lines):
    if re.match(r'^\s*#\s*include\b', line):
      return i
  return None

def insert_includes(text, includes_to_add):
  lines = text.splitlines(True)  # keep newlines
  idx = first_include_index(lines)
  if idx is None:
    # No includes found: insert at very top
    insert_at = 0
  else:
    # Insert right before the first include to keep system includes near top
    insert_at = idx

  block = "".join([f"#include <{h}>\n" for h in includes_to_add])
  lines.insert(insert_at, block)
  return "".join(lines)

# Parse rules: each rule is "add:<header>"
to_add = []
for r in rules:
  if not r.startswith("add:"):
    raise SystemExit(f"Bad rule: {r}")
  hdr = r.split(":", 1)[1]
  if not has_include(hdr):
    to_add.append(hdr)

if to_add:
  text = insert_includes(text, to_add)

if text != orig:
  path.write_text(text, encoding="utf-8")
  print(f"patched: {path} (added: {', '.join(to_add)})")
else:
  print(f"ok:      {path} (no changes)")
PY
}

echo "== ish64 header patcher =="
echo "Root: $ROOT"
echo

TARGETS=(
  "$ROOT/kernel/init.c"
  "$ROOT/emu/tinyemu/slirp/tcp_input.c"
  "$ROOT/emu/tinyemu/slirp/socket.c"
  "$ROOT/fs/sock.c"
)

for f in "${TARGETS[@]}"; do
  if ! file_exists "$f"; then
    echo "skip:   $f (not found)"
    continue
  fi

  case "$f" in
    */kernel/init.c)
      python_patch "$f" "add:signal.h"
      ;;
    */emu/tinyemu/slirp/tcp_input.c|*/emu/tinyemu/slirp/socket.c)
      python_patch "$f" "add:errno.h" "add:string.h"
      ;;
    */fs/sock.c)
      python_patch "$f" "add:errno.h"
      ;;
  esac
done

echo
echo "Done."
echo "Recommended clean build:"
echo "  rm -rf ~/Library/Developer/Xcode/DerivedData/ish64_ios-*"
echo "  xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore clean build"
