#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/Projects/ish64}"

say() { printf '\n==> %s\n' "$*"; }
fail() { echo "ERROR: $*" >&2; exit 1; }

[ -d "$ROOT" ] || fail "Project root not found: $ROOT"

backup_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  cp -n "$f" "$f.bak_patch" 2>/dev/null || true
}

append_if_missing() {
  local file="$1"
  local needle="$2"
  local text="$3"
  if ! grep -Fq "$needle" "$file"; then
    printf '%s\n' "$text" >> "$file"
  fi
}

insert_after_first_match() {
  local file="$1"
  local pattern="$2"
  local text="$3"
  python3 - "$file" "$pattern" "$text" <<'PY'
import sys, re
path, pattern, text = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'r', encoding='utf-8') as f:
    s = f.read()
if text in s:
    sys.exit(0)
m = re.search(pattern, s, flags=re.M)
if not m:
    sys.exit(1)
idx = m.end()
s = s[:idx] + "\n" + text + s[idx:]
with open(path, 'w', encoding='utf-8') as f:
    f.write(s)
PY
}

replace_text() {
  local file="$1"
  local old="$2"
  local new="$3"
  python3 - "$file" "$old" "$new" <<'PY'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'r', encoding='utf-8') as f:
    s = f.read()
if old not in s:
    sys.exit(0)
s = s.replace(old, new)
with open(path, 'w', encoding='utf-8') as f:
    f.write(s)
PY
}

say "Backing up touched files"
for f in \
  "$ROOT/fs/tty.c" \
  "$ROOT/fs/dev.h" \
  "$ROOT/fs/real.c" \
  "$ROOT/kernel/fs.h" \
  "$ROOT/fs/tmp.c"
do
  backup_file "$f"
done

say "Patch 1: make struct dev_ops visible in fs/tty.c"
TTY_C="$ROOT/fs/tty.c"
if [ -f "$TTY_C" ]; then
  insert_after_first_match "$TTY_C" '^#include "fs/tty\.h"' '#include "fs/devices.h"' || true
fi

say "Patch 2: add dev compatibility helpers in fs/dev.h"
DEV_H="$ROOT/fs/dev.h"
if [ -f "$DEV_H" ]; then
  # Ensure stdint is available
  insert_after_first_match "$DEV_H" '^#include <sys/types\.h>' '#include <stdint.h>' || true

  # Add BSD/Darwin compatibility typedefs if missing
  append_if_missing "$DEV_H" 'typedef unsigned int u_int;' '
/* Darwin / BSD style compatibility typedefs for iPhoneOS SDK headers */
#ifndef __U_INT_DEFINED_ISH64
#define __U_INT_DEFINED_ISH64
typedef unsigned int u_int;
#endif

#ifndef __U_CHAR_DEFINED_ISH64
#define __U_CHAR_DEFINED_ISH64
typedef unsigned char u_char;
#endif

#ifndef __U_SHORT_DEFINED_ISH64
#define __U_SHORT_DEFINED_ISH64
typedef unsigned short u_short;
#endif
'

  # Add alias helpers expected by some patched files
  append_if_missing "$DEV_H" 'static inline dev_t_ dev_fake_from_real(dev_t dev)' '
static inline dev_t_ dev_fake_from_real(dev_t dev) {
    return fake_dev(dev);
}

static inline dev_t dev_real_from_fake(dev_t_ dev) {
    return real_dev(dev);
}
'
fi

say "Patch 3: ensure fs/real.c sees BSD integer aliases before netinet/ip.h path chain"
REAL_C="$ROOT/fs/real.c"
if [ -f "$REAL_C" ]; then
  insert_after_first_match "$REAL_C" '^#include "fs/dev\.h"' '#include <stdint.h>' || true
fi

say "Patch 4: fix forward declaration visibility warning in kernel/fs.h"
KFS_H="$ROOT/kernel/fs.h"
if [ -f "$KFS_H" ]; then
  insert_after_first_match "$KFS_H" '^#include' '#include "fs/fd.h"' || true
fi

say "Patch 5: normalize tmp.c include if it still references kernel/file.h"
TMP_C="$ROOT/fs/tmp.c"
if [ -f "$TMP_C" ]; then
  replace_text "$TMP_C" '#include "kernel/file.h"' '#include "fs/file.h"'
fi

say "Patch 6: optional safety include for tty.h users"
TTY_H="$ROOT/fs/tty.h"
if [ -f "$TTY_H" ]; then
  backup_file "$TTY_H"
  insert_after_first_match "$TTY_H" '^#include' '#include "fs/devices.h"' || true
fi

say "Patch complete"

cat <<EOF

Next steps:

1. Clean:
   rm -rf "$ROOT/ios/build-xcode/build" ~/Library/Developer/Xcode/DerivedData/ish64_ios-*

2. Rebuild:
   cd "$ROOT/ios/build-xcode"
   xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore

If it fails again, send only the first 80-120 lines around the NEXT real error.
Ignore warnings unless they become errors.

EOF

