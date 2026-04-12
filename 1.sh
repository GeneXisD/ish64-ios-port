#!/bin/bash
# ish64_auto_fixes.sh
# Automatically fix fiber_frame, asbestos_invalidate_page, and errno issues

set -e

echo "=== Applying ish64 auto-fixes ==="

# 1️⃣ Add full fiber_frame definition if missing
FIBER_HEADER="asbestos/fiber_block.h"
if [ ! -f "$FIBER_HEADER" ]; then
  echo "Creating $FIBER_HEADER with full struct fiber_frame..."
  mkdir -p asbestos
  cat > "$FIBER_HEADER" <<'EOF'
#ifndef FIBER_BLOCK_H
#define FIBER_BLOCK_H

#include <stdint.h>

struct fiber_frame {
    void *bp;
    void *sp;
    void *ip;
    void *regs;
    void *ret_cache;
};

#endif
EOF
else
  echo "$FIBER_HEADER exists, ensure it has full struct fiber_frame definition."
fi

# Ensure offsets.c includes fiber_block.h first
OFFSETS_FILE="asbestos/offsets.c"
if ! grep -q "fiber_block.h" "$OFFSETS_FILE"; then
  echo "Adding #include \"fiber_block.h\" to $OFFSETS_FILE"
  sed -i '' '1i\
#include "fiber_block.h"
' "$OFFSETS_FILE"
fi

# 2️⃣ Fix asbestos_invalidate_page casts in kernel/memory.c
MEMORY_FILE="kernel/memory.c"
if grep -q "asbestos_invalidate_page" "$MEMORY_FILE"; then
  echo "Adding (void*)(uintptr_t) cast to asbestos_invalidate_page calls..."
  perl -pi -e 's/asbestos_invalidate_page\(([^,]+),\s*([^)]+)\)/asbestos_invalidate_page($1, (void*)(uintptr_t)$2)/g' "$MEMORY_FILE"
fi

# 3️⃣ Include errno.h in kernel/exec.c if missing
EXEC_FILE="kernel/exec.c"
if ! grep -q "<errno.h>" "$EXEC_FILE"; then
  echo "Including <errno.h> in $EXEC_FILE..."
  sed -i '' '1i\
#include <errno.h>
' "$EXEC_FILE"
fi

echo "=== Auto-fixes applied successfully ==="
