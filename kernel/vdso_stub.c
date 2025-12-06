// kernel/vdso_stub.c
// Minimal VDSO stubs for non-Linux (macOS/iOS) builds.

#include "kernel/vdso.h"

/*
 * vdso.h declares:
 *
 *   extern const char vdso_data[VDSO_PAGES * (1 << 12)] __asm__("vdso_data");
 *   int vdso_symbol(const char *name);
 *
 * On macOS/iOS we don't actually use a VDSO, we just need these
 * symbols to exist so the linker can resolve references.
 */

// Definition matching vdso.h exactly.
const char vdso_data[VDSO_PAGES * (1 << 12)] __asm__("vdso_data") = { 0 };

/*
 * Dummy implementation: on non-Linux hosts we always "fail"
 * to find a VDSO symbol.
 */
int vdso_symbol(const char *name) {
    (void)name;
    return -1;
}

