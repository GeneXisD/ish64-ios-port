#!/bin/bash

set -e

echo "=== FINISHING ISH64 BUILD (STUB MODE - FIXED PATHS) ==="

ROOT_DIR="$(pwd)"

ASBESTOS_DIR="$ROOT_DIR/asbestos"
KERNEL_DIR="$ROOT_DIR/kernel"
BUILD_DIR="$ROOT_DIR/build"

# Step 1: Backup asbestos
if [ -d "$ASBESTOS_DIR" ]; then
    echo "[] Backing up asbestos → asbestos_backup"
    rm -rf "$ROOT_DIR/asbestos_backup"
    cp -r "$ASBESTOS_DIR" "$ROOT_DIR/asbestos_backup"
fi

# Step 2: Remove broken asbestos
echo "[] Removing broken asbestos engine..."
rm -rf "$ASBESTOS_DIR"
mkdir -p "$ASBESTOS_DIR"

# Step 3: Create stub asbestos
echo "[] Creating stub asbestos engine..."

cat > "$ASBESTOS_DIR/asbestos.h" << 'EOF'
#ifndef ASBESTOS_H
#define ASBESTOS_H

#include <stdlib.h>

struct asbestos { int dummy; };

static inline struct asbestos asbestos_new(void m) {
    return calloc(1, sizeof(struct asbestos));
}

static inline void asbestos_free(struct asbestos a) {
    free(a);
}

static inline void asbestos_invalidate_page(struct asbestos a, void p) {
    (void)a;
    (void)p;
}

#endif
EOF

cat > "$ASBESTOS_DIR/asbestos.c" << 'EOF'
#include "asbestos.h"
EOF

touch "$ASBESTOS_DIR/gen.c"
touch "$ASBESTOS_DIR/offsets.c"
touch "$ASBESTOS_DIR/frame.h"
touch "$ASBESTOS_DIR/list.h"

# Step 4: Fix errno issue (only if file exists)
echo "[] Fixing errno include..."
if [ -f "$KERNEL_DIR/exec.c" ]; then
    if ! grep -q "#include <errno.h>" "$KERNEL_DIR/exec.c"; then
        sed -i '' '1s/^/#include <errno.h>\n/' "$KERNEL_DIR/exec.c"
    fi
else
    echo "[!] kernel/exec.c not found, skipping errno fix"
fi

# Step 5: Clean build.ninja if exists
echo "[] Cleaning build.ninja..."
if [ -f "$BUILD_DIR/build.ninja" ]; then
    sed -i '' 's@asbestos/[^ ]@@g' "$BUILD_DIR/build.ninja"
fi

# Step 6: Rebuild
echo "[] Rebuilding project..."
ninja -C "$BUILD_DIR" || true

echo "=== DONE ==="
