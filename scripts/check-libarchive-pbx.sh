#!/usr/bin/env bash
set -e

PBX="deps/libarchive.xcodeproj/project.pbxproj"
ROOT="deps/libarchive/libarchive"

echo "[*] Checking libarchive references..."

grep -E 'path = .*\.c;' "$PBX" | sed -E 's/.*path = ([^;]+);.*/\1/' | while read f; do
  if [ ! -f "$ROOT/$f" ]; then
    echo "[MISSING] $ROOT/$f"
  fi
done

echo "[✓] check complete"

