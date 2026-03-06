#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/Projects/ish64}"
cd "$ROOT"

echo "[*] Working in: $ROOT"

ts="$(date +%Y%m%d-%H%M%S)"
cp -av fs/poll.c "fs/poll.c.bak.${ts}"
cp -av fs/real.c "fs/real.c.bak.${ts}"

python3 <<'PY'
from pathlib import Path
import re

# -------------------------
# Fix fs/poll.c
# -------------------------
poll = Path("fs/poll.c")
text = poll.read_text()

# Remove duplicate errno includes we accidentally stacked
lines = text.splitlines()
seen_errno = False
out = []
for line in lines:
    if line.strip() == "#include <errno.h>":
        if seen_errno:
            continue
        seen_errno = True
    out.append(line)
text = "\n".join(out) + "\n"

# Force errno symbols to be visible even if SDK headers are weird
if "extern int errno;" not in text:
    m = re.search(r'(#include .*?\n)+', text)
    insert = "#include <errno.h>\nextern int errno;\n#ifndef EINTR\n#define EINTR 4\n#endif\n#ifndef EAGAIN\n#define EAGAIN 35\n#endif\n"
    if m:
        text = text[:m.end()] + insert + text[m.end():]
    else:
        text = insert + text

poll.write_text(text)

# -------------------------
# Fix fs/real.c
# -------------------------
real = Path("fs/real.c")
text = real.read_text()

# Remove duplicated errno include if we inserted it twice
lines = text.splitlines()
seen_errno = False
out = []
for line in lines:
    if line.strip() == "#include <errno.h>":
        if seen_errno:
            continue
        seen_errno = True
    out.append(line)
text = "\n".join(out) + "\n"

# The duplicate ip_v/ip_hl issue is usually caused by endian macros already
# being defined in a way Darwin's ip.h doesn't like. Easiest safe move:
# neutralize the host netinet/ip.h inclusion path from fs/sock.h side.
#
# Since fs/real.c only needs sock.h transitively through kernel/calls.h,
# inject a temporary undef before that include path is hit.
#
# We do this by adding a compatibility block before kernel/calls.h is reached.
marker = '#include "kernel/errno.h"\n'
compat = r'''#include "kernel/errno.h"

#if defined(__APPLE__)
/*
 * Prevent Darwin netinet/ip.h bitfield duplication on iPhoneOS 26 headers.
 * Let the system header choose its own path.
 */
#ifdef _IP_VHL
#undef _IP_VHL
#endif
#ifdef BYTE_ORDER
#undef BYTE_ORDER
#endif
#ifdef BIG_ENDIAN
#undef BIG_ENDIAN
#endif
#ifdef LITTLE_ENDIAN
#undef LITTLE_ENDIAN
#endif
#endif
'''
if marker in text and "_IP_VHL" not in text:
    text = text.replace(marker, compat, 1)

real.write_text(text)
PY

chmod +x tools/fix_ios26_round4.sh

echo
echo "[*] Quick verification: fs/poll.c"
grep -nE 'errno|EINTR|EAGAIN' fs/poll.c | head -20 || true

echo
echo "[*] Quick verification: fs/real.c"
grep -nE '_IP_VHL|BYTE_ORDER|BIG_ENDIAN|LITTLE_ENDIAN|kernel/errno.h' fs/real.c | head -20 || true

echo
echo "[*] Rebuilding ishcore"
cd ios/build-xcode
xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore 2>&1 | tee /tmp/ish64-build.log || true

echo
echo "[*] Top build errors"
grep -nE "error:|fatal error:" /tmp/ish64-build.log | /usr/bin/head -30 || true
