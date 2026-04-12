// at top of auxv.c, add this include for alloca on macOS
#if defined(__APPLE__)
#include <alloca.h>
#endif
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "linuxu.h"

// Auxv tags (define each independently for portability)
#ifndef AT_NULL
#define AT_NULL     0
#endif
#ifndef AT_IGNORE
#define AT_IGNORE   1
#endif
#ifndef AT_EXECFD
#define AT_EXECFD   2
#endif
#ifndef AT_PHDR
#define AT_PHDR     3
#endif
#ifndef AT_PHENT
#define AT_PHENT    4
#endif
#ifndef AT_PHNUM
#define AT_PHNUM    5
#endif
#ifndef AT_PAGESZ
#define AT_PAGESZ   6
#endif
#ifndef AT_BASE
#define AT_BASE     7
#endif
#ifndef AT_FLAGS
#define AT_FLAGS    8
#endif
#ifndef AT_ENTRY
#define AT_ENTRY    9
#endif
#ifndef AT_HWCAP
#define AT_HWCAP    16
#endif
#ifndef AT_CLKTCK
#define AT_CLKTCK   17
#endif
#ifndef AT_PLATFORM
#define AT_PLATFORM 15
#endif
#ifndef AT_RANDOM
#define AT_RANDOM   25
#endif

#ifndef HWCAP_FP
#define HWCAP_FP     (1UL << 0)
#define HWCAP_ASIMD  (1UL << 1)
#define HWCAP_AES    (1UL << 3)
#define HWCAP_PMULL  (1UL << 4)
#define HWCAP_SHA1   (1UL << 5)
#define HWCAP_SHA2   (1UL << 6)
#endif

typedef struct {
    void   *sp_base;
    size_t  sp_size;
    void   *sp_top;
} stack_image_t;

int build_initial_stack(char **argv, char **envp,
                        uint64_t at_entry, uint64_t at_phdr, uint64_t at_phent,
                        uint64_t at_phnum, size_t host_pagesz,
                        stack_image_t *out)
{
  (void)host_pagesz;  // not used yet; kept for future page-size logic

    if (!argv || !out) return -1;

    size_t argc = 0, envc = 0;
    while (argv[argc]) argc++;
    if (envp) while (envp[envc]) envc++;

    size_t cap = 64 * 1024;
    uint8_t *buf = (uint8_t*)malloc(cap);
    if (!buf) return -1;
    memset(buf, 0, cap);

    uint8_t *end = buf + cap;
    uint8_t *sp  = end;

    uint8_t rand16[16];
    for (int i=0;i<16;i++) rand16[i] = (uint8_t)rand();

    char **envp_addrs = (char**)alloca(sizeof(char*) * (envc ? envc : 1));
    for (ssize_t i=(ssize_t)envc-1; i>=0; --i) {
        size_t len = strlen(envp[i]) + 1;
        sp -= len;
        memcpy(sp, envp[i], len);
        envp_addrs[i] = (char*)sp;
    }
    char **argv_addrs = (char**)alloca(sizeof(char*) * (argc ? argc : 1));
    for (ssize_t i=(ssize_t)argc-1; i>=0; --i) {
        size_t len = strlen(argv[i]) + 1;
        sp -= len;
        memcpy(sp, argv[i], len);
        argv_addrs[i] = (char*)sp;
    }

    sp -= sizeof(rand16);
    memcpy(sp, rand16, sizeof(rand16));
    void *at_random_ptr = sp;

    uintptr_t spv = (uintptr_t)sp;
    spv &= ~((uintptr_t)15);
    sp = (uint8_t*)spv;

    uint64_t *w = (uint64_t*)buf;
    size_t idx = 0;
    w[idx++] = (uint64_t)argc;
    for (size_t i=0;i<argc;i++) w[idx++] = (uint64_t)(uintptr_t)argv_addrs[i];
    w[idx++] = 0;
    for (size_t i=0;i<envc;i++) w[idx++] = (uint64_t)(uintptr_t)envp_addrs[i];
    w[idx++] = 0;

    w[idx++] = AT_PAGESZ;   w[idx++] = (uint64_t)4096;
    w[idx++] = AT_CLKTCK;   w[idx++] = (uint64_t)100;
    w[idx++] = AT_PLATFORM; w[idx++] = (uint64_t)(uintptr_t)"aarch64";
    w[idx++] = AT_HWCAP;    w[idx++] = (uint64_t)(HWCAP_FP | HWCAP_ASIMD | HWCAP_AES | HWCAP_PMULL | HWCAP_SHA1 | HWCAP_SHA2);
    if (at_phdr)  { w[idx++] = AT_PHDR;  w[idx++] = at_phdr;  }
    if (at_phent) { w[idx++] = AT_PHENT; w[idx++] = at_phent; }
    if (at_phnum) { w[idx++] = AT_PHNUM; w[idx++] = at_phnum; }
    if (at_entry) { w[idx++] = AT_ENTRY; w[idx++] = at_entry; }
    w[idx++] = AT_RANDOM;   w[idx++] = (uint64_t)(uintptr_t)at_random_ptr;
    w[idx++] = AT_NULL;     w[idx++] = 0;

    out->sp_base = buf;
    out->sp_size = cap;
    out->sp_top  = w;
    return 0;
}

void dump_initial_stack(stack_image_t *st) {
    if (!st) return;
    fprintf(stderr, "[stack] base=%p size=%zu top=%p\n", st->sp_base, st->sp_size, st->sp_top);
    uint64_t *p = (uint64_t*)st->sp_top;
    size_t i = 0;
    uint64_t argc = p[i++];
    fprintf(stderr, " argc=%llu\n", (unsigned long long)argc);
    fprintf(stderr, " argv:\n");
    for (uint64_t a=0; a<argc; a++) {
        const char *s = (const char*)(uintptr_t)p[i++];
        fprintf(stderr, "  [%llu] \"%s\"\n", (unsigned long long)a, s);
    }
    i++; // NULL
    fprintf(stderr, " envp:\n");
    while (p[i]) {
        const char *s = (const char*)(uintptr_t)p[i++];
        fprintf(stderr, "  - %s\n", s);
    }
    i++; // NULL
    fprintf(stderr, " auxv:\n");
    while (p[i] != 0) {
        uint64_t k = p[i++];
        uint64_t v = p[i++];
        fprintf(stderr, "  %llu -> 0x%llx\n",
                (unsigned long long)k, (unsigned long long)v);
    }
}
