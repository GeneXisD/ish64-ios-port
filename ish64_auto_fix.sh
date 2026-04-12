#!/bin/bash
echo "=== Starting ish64 auto-fix (macOS) ==="

# List of source files that need includes
FILES=(
  "asbestos/gen.c"
  "asbestos/offsets.c"
  "asbestos/kernel_memory.c"
  "asbestos/gadgets-aarch64/control.S"
  "asbestos/gadgets-aarch64/bits.S"
)

# Add fiber_block.h and asbestos.h includes if missing
for file in "${FILES[@]}"; do
  echo "Checking $file ..."

  if [[ "$file" == *.c ]]; then
    # Add fiber_block.h
    if ! grep -q "fiber_block.h" "$file"; then
      sed -i.bak $'1i\\\n#include "fiber_block.h"\n' "$file"
      echo "  -> Added fiber_block.h include"
    fi

    # Add asbestos.h
    if ! grep -q "asbestos.h" "$file"; then
      sed -i.bak $'1i\\\n#include "asbestos.h"\n' "$file"
      echo "  -> Added asbestos.h include"
    fi
  fi
done

echo "=== Fixing AArch64 register macro issues ==="
# Patch common AArch64 bits/control issues
PATCHES=$(cat <<'EOF'
--- a/asbestos/gadgets-aarch64/control.S
+++ b/asbestos/gadgets-aarch64/control.S
@@
-    ldr w8, [_cpu, CPU_flags_res]
+    add x9, _cpu, #CPU_flags_res
+    ldr w8, [x9]
-    ldr w8, [_cpu, CPU_eflags]
+    add x9, _cpu, #CPU_eflags
+    ldr w8, [x9]
EOF
)

echo "$PATCHES" > temp.patch
patch -p0 < temp.patch && echo "  -> Applied control.S patch" || echo "  -> Skipped control.S patch (already applied or failed)"
rm temp.patch

echo "=== ish64 auto-fix complete ==="
