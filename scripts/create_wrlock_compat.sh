#!/usr/bin/env bash
set -euo pipefail

# location to create compatibility header relative to project root
COMPAT_PATH="util/wrlock_compat.h"

if [ -f "$COMPAT_PATH" ]; then
  echo "Compat header already exists: $COMPAT_PATH — not overwriting."
  exit 0
fi

mkdir -p "$(dirname "$COMPAT_PATH")"

cat > "$COMPAT_PATH" <<'EOF'
/* wrlock_compat.h
 * Declarations-only compatibility header to silence implicit declaration errors
 * If implementations don't exist, you'll see linker errors. At that point,
 * implement wrappers in util/wrlock_compat.c or change calls to match project API.
 */
#ifndef WRLOCK_COMPAT_H
#define WRLOCK_COMPAT_H

/* These prototypes match the functions the kernel code expects to call.
 * They are intentionally untyped (void*) to be easy to match many lock struct types.
 * If you have a lock_t type and functions, update signatures appropriately.
 */

#ifdef __cplusplus
extern "C" {
#endif

void wrlock_init(void *lock);
void write_wrlock(void *lock);
void write_wrunlock(void *lock);
void wrlock_destroy(void *lock);

#ifdef __cplusplus
}
#endif

#endif /* WRLOCK_COMPAT_H */
EOF

echo "Created util/wrlock_compat.h (declarations only)."

