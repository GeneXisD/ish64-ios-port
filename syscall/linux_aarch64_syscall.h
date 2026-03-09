#ifndef ISH_LINUX_AARCH64_SYSCALL_H
#define ISH_LINUX_AARCH64_SYSCALL_H
#include <stdint.h>
typedef struct linux_aarch64_regs {
    uint64_t x[31];
    uint64_t sp;
    uint64_t pc;
    uint64_t pstate;
} linux_aarch64_regs_t;
long linux_aarch64_dispatch_syscall(linux_aarch64_regs_t *regs);
#endif
