#!/bin/sh
set -e

BASE="$HOME/Projects/ish64"
FILE="$BASE/emu/tinyemu/slirp/misc.h"

echo "🔍 Checking for file:"
echo "   $FILE"
echo

if [ ! -f "$FILE" ]; then
  echo "❌ FILE NOT FOUND"
  echo
  echo "Let’s prove what DOES exist instead:"
  echo
  echo "📂 Contents of slirp directory:"
  ls -la "$BASE/emu/tinyemu/slirp" || true
  exit 1
fi

echo "✅ File found. Applying patch…"
cp "$FILE" "$FILE.bak"

perl -0777 -i -pe '
s/#define\s+fallthrough\s+__attribute__\s*\(\(fallthrough\)\)/#ifndef fallthrough\n#if defined(__has_attribute)\n#if __has_attribute(fallthrough)\n#define fallthrough __attribute__((fallthrough))\n#else\n#define fallthrough\n#endif\n#else\n#define fallthrough\n#endif\n#endif/s
' "$FILE"

echo
echo "🎉 Patch applied successfully."
echo "📦 Backup created at: $FILE.bak"

