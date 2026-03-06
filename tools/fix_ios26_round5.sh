#!/usr/bin/env bash
set -euo pipefail

cd ~/Projects/ish64

echo "[*] Restoring clean sources from git"
git checkout -- fs/real.c emu/tinyemu/slirp/ip_icmp.c

cp fs/real.c fs/real.c.bak.$(date +%Y%m%d-%H%M%S)
cp emu/tinyemu/slirp/ip_icmp.c emu/tinyemu/slirp/ip_icmp.c.bak.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

# ---- patch ip_icmp.c: add errno include if missing
p = Path("emu/tinyemu/slirp/ip_icmp.c")
text = p.read_text()
if "#include <errno.h>" not in text:
    lines = text.splitlines()
    inserted = False
    out = []
    for line in lines:
        out.append(line)
        if not inserted and line.startswith("#include"):
            # insert after the include block's first few lines
            pass
    # simpler: place near top before first project include
    first_project = text.find('#include "')
    if first_project != -1:
        text = text[:first_project] + '#include <errno.h>\n' + text[first_project:]
    else:
        text = '#include <errno.h>\n' + text
    p.write_text(text)

# ---- patch fs/real.c minimally
p = Path("fs/real.c")
text = p.read_text()

# add missing standard includes near the top if absent
needed = ['#include <errno.h>\n', '#include <poll.h>\n']
for inc in reversed(needed):
    if inc.strip() not in text:
        first_project = text.find('#include "')
        if first_project != -1:
            text = text[:first_project] + inc + text[first_project:]
        else:
            text = inc + text

# add stat time compatibility macros once
if "REAL_ST_ATIME_SEC" not in text:
    marker = '#include "kernel/errno.h"\n'
    compat = r'''
#include "kernel/errno.h"

#if defined(__APPLE__)
#ifndef AT_SYMLINK_NOFOLLOW
#define AT_SYMLINK_NOFOLLOW 0
#endif
#endif

#if defined(__APPLE__)
#define REAL_ST_ATIME_SEC(stp)   ((stp)->st_atimespec.tv_sec)
#define REAL_ST_MTIME_SEC(stp)   ((stp)->st_mtimespec.tv_sec)
#define REAL_ST_CTIME_SEC(stp)   ((stp)->st_ctimespec.tv_sec)
#define REAL_ST_ATIME_NSEC(stp)  ((stp)->st_atimespec.tv_nsec)
#define REAL_ST_MTIME_NSEC(stp)  ((stp)->st_mtimespec.tv_nsec)
#define REAL_ST_CTIME_NSEC(stp)  ((stp)->st_ctimespec.tv_nsec)
#else
#define REAL_ST_ATIME_SEC(stp)   ((stp)->st_atim.tv_sec)
#define REAL_ST_MTIME_SEC(stp)   ((stp)->st_mtim.tv_sec)
#define REAL_ST_CTIME_SEC(stp)   ((stp)->st_ctim.tv_sec)
#define REAL_ST_ATIME_NSEC(stp)  ((stp)->st_atim.tv_nsec)
#define REAL_ST_MTIME_NSEC(stp)  ((stp)->st_mtim.tv_nsec)
#define REAL_ST_CTIME_NSEC(stp)  ((stp)->st_ctim.tv_nsec)
#endif

'''
    if marker in text:
        text = text.replace(marker, compat, 1)

# replace direct stat field accesses if present
text = text.replace("real_stat->st_atimespec.tv_sec", "REAL_ST_ATIME_SEC(real_stat)")
text = text.replace("real_stat->st_mtimespec.tv_sec", "REAL_ST_MTIME_SEC(real_stat)")
text = text.replace("real_stat->st_ctimespec.tv_sec", "REAL_ST_CTIME_SEC(real_stat)")
text = text.replace("real_stat->st_atimespec.tv_nsec", "REAL_ST_ATIME_NSEC(real_stat)")
text = text.replace("real_stat->st_mtimespec.tv_nsec", "REAL_ST_MTIME_NSEC(real_stat)")
text = text.replace("real_stat->st_ctimespec.tv_nsec", "REAL_ST_CTIME_NSEC(real_stat)")
text = text.replace("real_stat->st_atim.tv_sec", "REAL_ST_ATIME_SEC(real_stat)")
text = text.replace("real_stat->st_mtim.tv_sec", "REAL_ST_MTIME_SEC(real_stat)")
text = text.replace("real_stat->st_ctim.tv_sec", "REAL_ST_CTIME_SEC(real_stat)")
text = text.replace("real_stat->st_atim.tv_nsec", "REAL_ST_ATIME_NSEC(real_stat)")
text = text.replace("real_stat->st_mtim.tv_nsec", "REAL_ST_MTIME_NSEC(real_stat)")
text = text.replace("real_stat->st_ctim.tv_nsec", "REAL_ST_CTIME_NSEC(real_stat)")

# If previous manual edits left stray endif block around fake_stat section, clean only the obvious bad fragment.
bad_fragment = """  #endif
#endif

    fake_stat->ctime_nsec = REAL_ST_CTIME_NSEC(real_stat);
}"""
if bad_fragment in text:
    text = text.replace(bad_fragment, "    fake_stat->ctime_nsec = REAL_ST_CTIME_NSEC(real_stat);\n}")

# neutralize fdopendir on Apple if undeclared by SDK
if "ish_fdopendir_fallback" not in text:
    insert_marker = "static int realfs_readdir"
    helper = r'''
#if defined(__APPLE__)
static DIR *ish_fdopendir_fallback(int dirfd) {
    char pathbuf[64];
    snprintf(pathbuf, sizeof(pathbuf), "/dev/fd/%d", dirfd);
    return opendir(pathbuf);
}
#endif

'''
    idx = text.find(insert_marker)
    if idx != -1:
        text = text[:idx] + helper + text[idx:]

text = text.replace("fdopendir(dirfd)", "ish_fdopendir_fallback(dirfd)")

p.write_text(text)
PY

echo
echo "[*] Verifying real.c for structural damage"
grep -nE '#endif without|fake_stat|st_atim|st_mtim|st_atimespec|st_mtimespec|fdopendir|ish_fdopendir_fallback|POLLIN|POLLOUT|errno' fs/real.c | /usr/bin/head -40 || true

echo
echo "[*] Verifying ip_icmp.c"
grep -n "errno.h\\|errno" emu/tinyemu/slirp/ip_icmp.c | /usr/bin/head -20 || true

echo
echo "[*] Rebuilding ishcore"
cd ios/build-xcode
xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore 2>&1 | tee /tmp/ish64-build.log || true

echo
echo "[*] Top build errors"
grep -nE "error:|fatal error:" /tmp/ish64-build.log | /usr/bin/head -40 || true
