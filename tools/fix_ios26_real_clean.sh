#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/Projects/ish64}"
cd "$ROOT"

echo "[*] Working in: $ROOT"

ts="$(date +%Y%m%d-%H%M%S)"
cp -av fs/real.c "fs/real.c.bak.${ts}"

echo
echo "[*] Restoring fs/real.c from git"
git restore fs/real.c

python3 <<'PY'
from pathlib import Path

p = Path("fs/real.c")
text = p.read_text()

# 1) add missing system headers once
header_anchor = '#include <sys/statvfs.h>\n'
header_block = '''#include <sys/statvfs.h>
#include <errno.h>
#include <poll.h>
#include <dirent.h>
#include <sys/param.h>
'''
if header_anchor in text and '#include <poll.h>' not in text:
    text = text.replace(header_anchor, header_block, 1)

# 2) add compatibility block after tinyemu include
anchor = '#include "emu/tinyemu/cutils.h"\n'
compat = r'''#include "emu/tinyemu/cutils.h"

#if defined(__APPLE__)
#ifndef AT_SYMLINK_NOFOLLOW
#define AT_SYMLINK_NOFOLLOW 0
#endif
#ifndef POLLPRI
#define POLLPRI 0x0002
#endif

/* iPhoneOS 26 headers expose BSD-style timespec fields */
#ifndef REAL_ST_ATIME_SEC
#define REAL_ST_ATIME_SEC(stp)   ((stp)->st_atimespec.tv_sec)
#endif
#ifndef REAL_ST_MTIME_SEC
#define REAL_ST_MTIME_SEC(stp)   ((stp)->st_mtimespec.tv_sec)
#endif
#ifndef REAL_ST_CTIME_SEC
#define REAL_ST_CTIME_SEC(stp)   ((stp)->st_ctimespec.tv_sec)
#endif
#ifndef REAL_ST_ATIME_NSEC
#define REAL_ST_ATIME_NSEC(stp)  ((stp)->st_atimespec.tv_nsec)
#endif
#ifndef REAL_ST_MTIME_NSEC
#define REAL_ST_MTIME_NSEC(stp)  ((stp)->st_mtimespec.tv_nsec)
#endif
#ifndef REAL_ST_CTIME_NSEC
#define REAL_ST_CTIME_NSEC(stp)  ((stp)->st_ctimespec.tv_nsec)
#endif

/* keep Darwin ip.h from exploding on duplicated bitfield layout */
#ifdef _IP_VHL
#undef _IP_VHL
#endif
#ifdef __LITTLE_ENDIAN__
#undef __LITTLE_ENDIAN__
#endif
#ifdef __BIG_ENDIAN__
#undef __BIG_ENDIAN__
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
if anchor in text and 'REAL_ST_ATIME_SEC' not in text:
    text = text.replace(anchor, compat, 1)

# 3) make fdopendir fallback visible before first use
fallback_decl = '\nstatic DIR *ish_fdopendir_fallback(int dirfd);\n'
if 'static DIR *ish_fdopendir_fallback(int dirfd);' not in text:
    insert_after = '#include "kernel/errno.h"\n'
    if insert_after in text:
        text = text.replace(insert_after, insert_after + fallback_decl, 1)

# 4) replace direct stat field usage with compat macros
text = text.replace('fake_stat->atime      = real_stat->st_atim.tv_sec;',
                    'fake_stat->atime      = REAL_ST_ATIME_SEC(real_stat);')
text = text.replace('fake_stat->mtime      = real_stat->st_mtim.tv_sec;',
                    'fake_stat->mtime      = REAL_ST_MTIME_SEC(real_stat);')
text = text.replace('fake_stat->ctime      = real_stat->st_ctim.tv_sec;',
                    'fake_stat->ctime      = REAL_ST_CTIME_SEC(real_stat);')
text = text.replace('fake_stat->atime_nsec = real_stat->st_atim.tv_nsec;',
                    'fake_stat->atime_nsec = REAL_ST_ATIME_NSEC(real_stat);')
text = text.replace('fake_stat->mtime_nsec = real_stat->st_mtim.tv_nsec;',
                    'fake_stat->mtime_nsec = REAL_ST_MTIME_NSEC(real_stat);')
text = text.replace('fake_stat->ctime_nsec = real_stat->st_ctim.tv_nsec;',
                    'fake_stat->ctime_nsec = REAL_ST_CTIME_NSEC(real_stat);')

text = text.replace('fake_stat->atime_nsec = (int64_t)real_stat->st_atim.tv_nsec;',
                    'fake_stat->atime_nsec = (int64_t)REAL_ST_ATIME_NSEC(real_stat);')
text = text.replace('fake_stat->mtime_nsec = (int64_t)real_stat->st_mtim.tv_nsec;',
                    'fake_stat->mtime_nsec = (int64_t)REAL_ST_MTIME_NSEC(real_stat);')
text = text.replace('fake_stat->ctime_nsec = (int64_t)real_stat->st_ctim.tv_nsec;',
                    'fake_stat->ctime_nsec = (int64_t)REAL_ST_CTIME_NSEC(real_stat);')

p.write_text(text)
PY

echo
echo "[*] Verification snippets"
grep -n 'REAL_ST_' fs/real.c | /usr/bin/head -20 || true
grep -n 'ish_fdopendir_fallback' fs/real.c | /usr/bin/head -20 || true
grep -n 'AT_SYMLINK_NOFOLLOW\|POLLPRI\|#include <poll.h>\|#include <errno.h>' fs/real.c | /usr/bin/head -20 || true

echo
echo "[*] Rebuilding ishcore"
cd ios/build-xcode
xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore 2>&1 | tee /tmp/ish64-build.log || true

echo
echo "[*] Top build errors"
grep -nE 'error:|fatal error:' /tmp/ish64-build.log | /usr/bin/head -30 || true
