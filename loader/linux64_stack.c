#include "linux64_stack.h"
#include <string.h>
#include <stdint.h>
static size_t count_vec(char *const vec[]) { size_t n = 0; if (!vec) return 0; while (vec[n] != NULL) n++; return n; }
static uint8_t *align_down(uint8_t *p, uintptr_t align) { uintptr_t x = (uintptr_t)p; x &= ~(align - 1); return (uint8_t *)x; }
int linux64_stack_build(linux64_stack_layout_t *layout, char *const argv[], char *const envp[]) {
    if (!layout || !layout->stack_base || layout->stack_size < 4096) return -1;
    uint8_t *base = layout->stack_base;
    uint8_t *sp = base + layout->stack_size;
    size_t argc = count_vec(argv), envc = count_vec(envp);
    uint64_t argv_ptrs[128], envp_ptrs[128];
    if (argc >= 128 || envc >= 128) return -1;
    for (ssize_t i = (ssize_t)envc - 1; i >= 0; i--) { size_t len = strlen(envp[i]) + 1; sp -= len; memcpy(sp, envp[i], len); envp_ptrs[i] = (uint64_t)(uintptr_t)sp; }
    for (ssize_t i = (ssize_t)argc - 1; i >= 0; i--) { size_t len = strlen(argv[i]) + 1; sp -= len; memcpy(sp, argv[i], len); argv_ptrs[i] = (uint64_t)(uintptr_t)sp; }
    sp = align_down(sp, 16);
    sp -= sizeof(uint64_t) * (1 + argc + 1 + envc + 1);
    uint64_t *u64sp = (uint64_t *)sp;
    size_t idx = 0;
    u64sp[idx++] = (uint64_t)argc;
    for (size_t i = 0; i < argc; i++) u64sp[idx++] = argv_ptrs[i];
    u64sp[idx++] = 0;
    for (size_t i = 0; i < envc; i++) u64sp[idx++] = envp_ptrs[i];
    u64sp[idx++] = 0;
    layout->guest_sp = (uint64_t)(uintptr_t)sp;
    return 0;
}
