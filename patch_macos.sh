#!/bin/bash
# patch_macos_fixed.sh
# Apply macOS compatibility fixes for ish64

set -e

echo "[*] Applying macOS fixed compatibility patches to ish64..."

# 1️⃣ Fix asbestos.h line mangling
ASBESTOS_H="asbestos/asbestos.h"
if grep -q "__APPLE__n#include" "$ASBESTOS_H"; then
    echo "[+] Fixing smashed #ifdef in $ASBESTOS_H"
    sed -i.bak 's|#ifdef __APPLE__n#include <pthread.h>ntypedef pthread_rwlock_t wrlock_t;n#define read_wrlock pthread_rwlock_rdlockn#define read_wrunlock pthread_rwlock_unlockn#endif|#ifdef __APPLE__\
#include <pthread.h>\
typedef pthread_rwlock_t wrlock_t;\
#define read_wrlock pthread_rwlock_rdlock\
#define read_wrunlock pthread_rwlock_unlock\
#endif|' "$ASBESTOS_H"
fi

# 2️⃣ Wrap stdatomic.h includes and atomic typedefs for Linux only
FRAME_H="asbestos/frame.h"
if ! grep -q "__APPLE__" "$FRAME_H"; then
    echo "[+] Wrapping stdatomic.h for Linux only in $FRAME_H"
    sed -i.bak 's|#include <stdatomic.h>|#ifndef __APPLE__\
#include <stdatomic.h>\
#endif|' "$FRAME_H"
fi

# 3️⃣ Fix include paths in fs/tty-real.c and fs/real.c
TTY_REAL="fs/tty-real.c"
REAL_C="fs/real.c"
if grep -q "#include \"fs/fs.h\"" "$TTY_REAL"; then
    echo "[+] Adjusting include path in $TTY_REAL"
    sed -i.bak 's|#include "fs/fs.h"|#include "fs.h"|' "$TTY_REAL"
fi
if grep -q "#include \"fs.h\"" "$REAL_C"; then
    echo "[+] Ensuring include path consistency in $REAL_C"
    # already ok, skip
    :
fi

# 4️⃣ Fix dev_open pointer type issue in fs/dev.c
DEV_C="fs/dev.c"
if grep -q "struct dev_ops \*dev; if (kind == DEV_BLOCK)" "$DEV_C"; then
    echo "[+] Fixing dev_ops pointer assignment in $DEV_C"
    sed -i.bak 's|struct dev_ops \*dev; if (kind == DEV_BLOCK) dev = block_devs; else dev = char_devs\[major\];|struct dev_ops *dev; if (kind == DEV_BLOCK) dev = block_devs[major]; else dev = char_devs[major];|' "$DEV_C"
fi

echo "[*] macOS compatibility patches applied successfully."
echo "[*] Backup files saved with .bak extension."
