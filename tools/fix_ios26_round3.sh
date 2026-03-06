#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/Projects/ish64}"
cd "$ROOT"

echo "[*] Working in: $ROOT"

need_file() {
  [[ -f "$1" ]] || { echo "[!] Missing file: $1" >&2; exit 1; }
}

need_file "fs/real.c"
need_file "fs/poll.c"

ts="$(date +%Y%m%d-%H%M%S)"
cp -av fs/real.c "fs/real.c.bak.${ts}"
cp -av fs/poll.c "fs/poll.c.bak.${ts}"

echo
echo "[*] Restoring fs/real.c from git to remove broken manual edits"
git restore fs/real.c || true

python3 <<'PY'
from pathlib import Path
import re

real = Path("fs/real.c")
text = real.read_text()

# 1) Add missing Darwin/iOS compatibility block near the top, after cutils include.
anchor = '#include "emu/tinyemu/cutils.h"\n'
block = r'''#include "emu/tinyemu/cutils.h"
#if defined(__APPLE__)
#include <sys/param.h>
#include <errno.h>
#include <poll.h>
#include <fcntl.h>

/*
 * iPhoneOS 26 SDK compatibility:
 * ensure endian macros exist before netinet/ip.h is reached through sock.h
 * and expose a few POSIX declarations/macros that the SDK headers do not
 * surface cleanly in this C mode.
 */
extern int fstatat(int, const char *, struct stat *, int);
extern DIR *fdopendir(int);

#ifndef AT_SYMLINK_NOFOLLOW
#define AT_SYMLINK_NOFOLLOW 0
#endif

#ifndef POLLPRI
#define POLLPRI 0x0002
#endif

#define REAL_ST_ATIME_SEC(stp)   ((stp)->st_atim.tv_sec)
#define REAL_ST_MTIME_SEC(stp)   ((stp)->st_mtim.tv_sec)
#define REAL_ST_CTIME_SEC(stp)   ((stp)->st_ctim.tv_sec)
#define REAL_ST_ATIME_NSEC(stp)  ((stp)->st_atim.tv_nsec)
#define REAL_ST_MTIME_NSEC(stp)  ((stp)->st_mtim.tv_nsec)
#define REAL_ST_CTIME_NSEC(stp)  ((stp)->st_ctim.tv_nsec)
#else
#define REAL_ST_ATIME_SEC(stp)   ((stp)->st_atimespec.tv_sec)
#define REAL_ST_MTIME_SEC(stp)   ((stp)->st_mtimespec.tv_sec)
#define REAL_ST_CTIME_SEC(stp)   ((stp)->st_ctimespec.tv_sec)
#define REAL_ST_ATIME_NSEC(stp)  ((stp)->st_atimespec.tv_nsec)
#define REAL_ST_MTIME_NSEC(stp)  ((stp)->st_mtimespec.tv_nsec)
#define REAL_ST_CTIME_NSEC(stp)  ((stp)->st_ctimespec.tv_nsec)
#endif
'''
if anchor in text and "REAL_ST_ATIME_SEC" not in text:
    text = text.replace(anchor, block, 1)

# 2) Replace stat field accesses with compatibility macros.
repls = {
    'real_stat->st_atimespec.tv_sec': 'REAL_ST_ATIME_SEC(real_stat)',
    'real_stat->st_mtimespec.tv_sec': 'REAL_ST_MTIME_SEC(real_stat)',
    'real_stat->st_ctimespec.tv_sec': 'REAL_ST_CTIME_SEC(real_stat)',
    'real_stat->st_atimespec.tv_nsec': 'REAL_ST_ATIME_NSEC(real_stat)',
    'real_stat->st_mtimespec.tv_nsec': 'REAL_ST_MTIME_NSEC(real_stat)',
    'real_stat->st_ctimespec.tv_nsec': 'REAL_ST_CTIME_NSEC(real_stat)',
    'real_stat->st_ctim.tv_nsec': 'REAL_ST_CTIME_NSEC(real_stat)',
    'real_stat->st_ctim.tv_sec': 'REAL_ST_CTIME_SEC(real_stat)',
}
for old, new in repls.items():
    text = text.replace(old, new)

# 3) If fdopendir is not available at compile time on this SDK, provide a fallback.
if "static DIR *ish_fdopendir_fallback" not in text:
    helper = r'''

#if defined(__APPLE__)
static DIR *ish_fdopendir_fallback(int dirfd) {
    DIR *d = fdopendir(dirfd);
    if (d != NULL)
        return d;

    char procpath[64];
    snprintf(procpath, sizeof(procpath), "/dev/fd/%d", dirfd);
    return opendir(procpath);
}
#endif
'''
    # place after fix_path helper if present, else append near top
    m = re.search(r'(static const char \*fix_path\(.*?\n\})', text, flags=re.S)
    if m:
        text = text[:m.end()] + helper + text[m.end():]
    else:
        text += helper

text = text.replace("fd->dir = fdopendir(dirfd);", "fd->dir = ish_fdopendir_fallback(dirfd);")

real.write_text(text)

poll = Path("fs/poll.c")
ptext = poll.read_text()

# Add errno include once.
if "#include <errno.h>" not in ptext:
    # insert after the first include block line if possible
    lines = ptext.splitlines()
    inserted = False
    out = []
    for line in lines:
        out.append(line)
        if not inserted and line.startswith("#include"):
            out.append("#include <errno.h>")
            inserted = True
    ptext = "\n".join(out) + "\n"

poll.write_text(ptext)
PY

echo
echo "[*] Verification"
echo "---- fs/real.c compatibility markers ----"
grep -nE 'REAL_ST_ATIME_SEC|fdopendir_fallback|AT_SYMLINK_NOFOLLOW|POLLPRI|sys/param.h|errno.h' fs/real.c || true
echo
echo "---- fs/poll.c errno include ----"
grep -n 'errno.h' fs/poll.c || true

echo
echo "[*] Rebuilding ishcore"
cd ios/build-xcode
xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore 2>&1 | tee /tmp/ish64-build.log || true

echo
echo "[*] Top build errors"
grep -nE "error:|fatal error:" /tmp/ish64-build.log | /usr/bin/head -30 || true
