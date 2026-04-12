#!/bin/bash
# fix_ish.sh - auto-fix main.c envp and generate syscall wrappers

set -e

MAIN_C="main.c"
SYSCALL_C="kernel/calls.c"
WRAPPER_H="kernel/syscall_wrappers.h"

echo "[*] Fixing main.c envp usage..."
# Backup first
cp "$MAIN_C" "$MAIN_C.bak"

# Replace unsafe envp handling
sed -i.bak 's|char envp\[100\] = {0};.*getenv("TERM").*strcpy(envp, getenv("TERM") - strlen("TERM") - 1);|const char *envp = getenv("TERM");\nif (!envp) envp = "TERM=xterm";|' "$MAIN_C"

echo "[*] Generating syscall wrappers header..."

cat > "$WRAPPER_H" <<'EOF'
#ifndef SYSCALL_WRAPPERS_H
#define SYSCALL_WRAPPERS_H

#include "kernel/calls.h"

// Macro to define a wrapper with up to 6 arguments, ignoring extras
#define WRAP_SYSCALL(name, nargs) \
static int syscall_##name##_wrapper(unsigned int a, unsigned int b, unsigned int c, \
                                   unsigned int d, unsigned int e, unsigned int f) { \
    return name(a,b,c,d,e,f); \
}

EOF

# Parse syscalls from calls.c (simple heuristic: lines with sys_ function)
grep -Po '^\s*\[\d+\]\s*=\s*\(syscall_t\)\s*\Ksys_\w+' "$SYSCALL_C" | sort -u | while read fn; do
    echo "WRAP_SYSCALL($fn, 6)" >> "$WRAPPER_H"
done

cat >> "$WRAPPER_H" <<'EOF'

#endif // SYSCALL_WRAPPERS_H
EOF

echo "[*] Done! Remember to include syscall_wrappers.h in calls.c and replace syscall_table entries with wrappers."
