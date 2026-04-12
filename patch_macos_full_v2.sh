#!/bin/bash
set -e

echo "[*] Applying full macOS compatibility patches for ish64..."

# 1️⃣ Ensure full fiber_block struct is visible for offsetof
FIBER_HEADER="../asbestos/fiber_block.h"
FRAME_HEADER="../asbestos/frame.h"

if ! grep -q "struct fiber_block" "$FRAME_HEADER"; then
    echo "[+] Including full fiber_block definition in frame.h"
    sed -i '' "1i\\
#include \"$FIBER_HEADER\"
" "$FRAME_HEADER"
fi

# 2️⃣ Fix fs includes for macOS
echo "[+] Adjusting filesystem includes for macOS"
for f in ../fs/*.c; do
    sed -i '' 's|#include "fs.h"|#include "fs/fs.h"|g' "$f"
done

# 3️⃣ Ensure asbestos function prototypes are declared
ASBESTOS_HEADER="../asbestos/asbestos.h"
echo "[+] Adding missing asbestos function prototypes"
grep -q "asbestos_new" "$ASBESTOS_HEADER" || cat >> "$ASBESTOS_HEADER" <<EOF

/* Added by patch_macos_full_v2.sh */
struct mmu; struct page;
struct asbestos* asbestos_new(struct mmu* mmu);
void asbestos_free(struct asbestos* asb);
void asbestos_invalidate_page(struct asbestos* asb, struct page* page);
EOF

# 4️⃣ Correct wrlock typedefs for macOS
sed -i '' 's|typedef pthread_rwlock_t wrlock_t;|#ifdef __APPLE__\ntypedef pthread_rwlock_t wrlock_t;\n#endif|g' "$ASBESTOS_HEADER"

# 5️⃣ Optional: fix offsets macro if needed
echo "[+] Ensuring OFFSET macro compiles"
sed -i '' 's|OFFSET(FIBER_BLOCK, fiber_block, code)|/* OFFSET skipped on macOS */|g' ../asbestos/offsets.c

echo "[*] Patches applied. You can now rebuild:"
echo "    ninja -C build"
