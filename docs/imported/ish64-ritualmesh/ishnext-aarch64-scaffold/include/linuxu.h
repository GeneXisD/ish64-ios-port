#pragma once
#include <stdint.h>
#include <stddef.h>

typedef struct linux_regs {
    uint64_t x[31];
    uint64_t sp;
    uint64_t pc;
    uint64_t pstate;
    uint64_t x8; // syscall number lives in x8 for aarch64
} linux_regs_t;

long linux_syscall_entry(linux_regs_t *r);

#define LINUX_ENOSYS 38
#define LINUX_EINVAL 22
#define LINUX_EFAULT 14
#define LINUX_EPERM  1

// Minimal auxv tags
#define AT_NULL     0
#define AT_PAGESZ   6
#define AT_CLKTCK   17
#define AT_RANDOM   25
#define AT_HWCAP    16
#define AT_PLATFORM 15

// Small helpers
static inline long neg(long x) { return -x; }
