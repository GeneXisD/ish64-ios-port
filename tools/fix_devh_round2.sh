#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/Projects/ish64}"
cd "$ROOT"

echo "[*] Working in: $ROOT"

need_file() {
  [[ -f "$1" ]] || { echo "[!] Missing file: $1" >&2; exit 1; }
}

need_file "fs/dev.h"
need_file "fs/fd.h"
need_file "fs/tty.c"

ts="$(date +%Y%m%d-%H%M%S)"
cp -av fs/dev.h "fs/dev.h.bak.${ts}"
cp -av fs/tty.c "fs/tty.c.bak.${ts}"

cat > fs/dev.h <<'EOF'
#ifndef FS_DEV_H
#define FS_DEV_H

#include <sys/types.h>
#include <stdint.h>

/*
 * Keep the fake/Linux-side device encoding stable inside ish:
 * high 16 bits = major
 * low  16 bits = minor
 */
typedef unsigned int dev_t_;

static inline dev_t_ dev_make(dev_t_ major_, dev_t_ minor_) {
    return ((major_ & 0xffffu) << 16) | (minor_ & 0xffffu);
}

static inline dev_t_ dev_major(dev_t_ dev) {
    return (dev >> 16) & 0xffffu;
}

static inline dev_t_ dev_minor(dev_t_ dev) {
    return dev & 0xffffu;
}

static inline dev_t real_dev(dev_t_ dev) {
    return (dev_t) dev;
}

static inline dev_t_ fake_dev(dev_t dev) {
    return (dev_t_) dev;
}

static inline dev_t dev_real_from_fake(dev_t_ dev) {
    return real_dev(dev);
}

static inline dev_t_ dev_fake_from_real(dev_t dev) {
    return fake_dev(dev);
}

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

/* forward declarations needed by dev_ops */
struct mount;
struct path;
struct statbuf;
struct poll;

/*
 * Important:
 * fs/fd.h must come AFTER dev_t_ is defined, because kernel/fs.h uses dev_t_.
 */
#include "fs/fd.h"

struct dev_ops {
    const char *name;
    int (*open)(int major, int minor, struct fd *fd);
    int (*getpath)(struct mount *mount, struct path *path, char *buf);
    int (*stat)(struct fd *fd, struct statbuf *stat);
    int (*readlink)(struct mount *mount, struct path *path, char *buf);
    struct fd_ops fd;
};

#endif
EOF

python3 <<'PY'
from pathlib import Path
import re

tty = Path("fs/tty.c")
text = tty.read_text()

# Ensure wrapper exists once
if "static int tty_dev_open_wrapper(int major, int minor, struct fd *fd)" not in text:
    wrapper = """
static int tty_dev_open_wrapper(int major, int minor, struct fd *fd) {
    return tty_device_open(major, minor, fd);
}

"""
    text = re.sub(r'(\bstruct\s+dev_ops\s+tty_dev\s*=\s*\{)', wrapper + r'\1', text, count=1)

text = text.replace(".open = tty_device_open,", ".open = tty_dev_open_wrapper,")

tty.write_text(text)
PY

echo
echo "[*] Quick verification"
echo "---- fs/dev.h ----"
sed -n '1,140p' fs/dev.h
echo
echo "---- tty wrapper count ----"
grep -n "tty_dev_open_wrapper" fs/tty.c || true

echo
echo "[*] Rebuilding ishcore"
cd ios/build-xcode
xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore 2>&1 | tee /tmp/ish64-build.log || true

echo
echo "[*] Top build errors"
grep -nE "error:|fatal error:" /tmp/ish64-build.log | /usr/bin/head -30 || true
