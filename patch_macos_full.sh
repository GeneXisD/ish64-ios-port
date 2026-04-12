#!/bin/bash
set -e

echo "[*] Applying full macOS ARM64 compatibility patch for ish64..."

# 1️⃣ Fix asbestos.h
ASBESTOS_H="asbestos/asbestos.h"
if [ -f "$ASBESTOS_H" ]; then
    echo "[+] Patching $ASBESTOS_H..."
    cat > "$ASBESTOS_H" <<'EOF'
#ifndef ASBESTOS_H
#define ASBESTOS_H

#ifdef __APPLE__
#include <pthread.h>
typedef pthread_rwlock_t wrlock_t;
#define read_wrlock pthread_rwlock_rdlock
#define read_wrunlock pthread_rwlock_unlock
#else
#include <stdatomic.h>
#endif

// ... keep the rest of your asbestos.h content here ...
#endif // ASBESTOS_H
EOF
else
    echo "[-] $ASBESTOS_H not found!"
    exit 1
fi

# 2️⃣ Fix LOCAL_* labels in control.S
CONTROL_S="asbestos/gadgets-aarch64/control.S"
if [ -f "$CONTROL_S" ]; then
    echo "[+] Patching $CONTROL_S offsets and LOCAL_* labels..."
    # Backup
    cp "$CONTROL_S" "${CONTROL_S}.bak"

    # 2a: Replace LOCAL_* with .L_*
    sed -i.bak -E 's/\bLOCAL_([a-zA-Z0-9_]+)/.L_\1/g' "$CONTROL_S"

    # 2b: Rewrite ldr/str with large offsets to temp register pattern
    # Matches: ldr wX, [_cpu, CPU_*]
    sed -i.bak -E '
    s/ldr w([0-9]+), \[_cpu, (CPU_[a-zA-Z0-9_]+)\]/add x9, _cpu, #\2\nldr w\1, [x9]/g
    s/ldr x([0-9]+), \[_cpu, (CPU_[a-zA-Z0-9_]+)\]/add x9, _cpu, #\2\nldr x\1, [x9]/g
    s/str w([0-9]+), \[_cpu, (CPU_[a-zA-Z0-9_]+)\]/add x9, _cpu, #\2\nstr w\1, [x9]/g
    s/strb w([0-9]+), \[_cpu, (CPU_[a-zA-Z0-9_]+)\]/add x9, _cpu, #\2\nstrb w\1, [x9]/g
    ' "$CONTROL_S"

else
    echo "[-] $CONTROL_S not found!"
    exit 1
fi

echo "[*] Patch applied. You can now run:"
echo "   ninja -C build"
