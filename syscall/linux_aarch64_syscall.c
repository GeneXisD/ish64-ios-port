#include "linux_aarch64_syscall.h"
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#ifndef MAP_ANON
#define MAP_ANON MAP_ANONYMOUS
#endif
typedef struct linux_utsname {
    char sysname[65]; char nodename[65]; char release[65];
    char version[65]; char machine[65]; char domainname[65];
} linux_utsname_t;
static long neg_errno(void) { return -errno; }
static int linux_to_host_open_flags(int flags) {
    int out = 0;
    switch (flags & O_ACCMODE) { case O_RDONLY: out |= O_RDONLY; break; case O_WRONLY: out |= O_WRONLY; break; case O_RDWR: out |= O_RDWR; break; default: out |= O_RDONLY; break; }
    if (flags & O_CREAT) out |= O_CREAT;
    if (flags & O_TRUNC) out |= O_TRUNC;
    if (flags & O_APPEND) out |= O_APPEND;
#ifdef O_CLOEXEC
    if (flags & O_CLOEXEC) out |= O_CLOEXEC;
#endif
    return out;
}
static long sys_read(linux_aarch64_regs_t *regs) { ssize_t rc = read((int)regs->x[0], (void *)(uintptr_t)regs->x[1], (size_t)regs->x[2]); return (rc < 0) ? neg_errno() : rc; }
static long sys_write(linux_aarch64_regs_t *regs) { ssize_t rc = write((int)regs->x[0], (const void *)(uintptr_t)regs->x[1], (size_t)regs->x[2]); return (rc < 0) ? neg_errno() : rc; }
static long sys_openat(linux_aarch64_regs_t *regs) { int rc = openat((int)regs->x[0], (const char *)(uintptr_t)regs->x[1], linux_to_host_open_flags((int)regs->x[2]), (int)regs->x[3]); return (rc < 0) ? neg_errno() : rc; }
static long sys_close(linux_aarch64_regs_t *regs) { int rc = close((int)regs->x[0]); return (rc < 0) ? neg_errno() : rc; }
static long sys_uname(linux_aarch64_regs_t *regs) {
    linux_utsname_t *u = (linux_utsname_t *)(uintptr_t)regs->x[0];
    if (!u) return -EFAULT;
    memset(u, 0, sizeof(*u));
    strncpy(u->sysname, "Linux", sizeof(u->sysname) - 1);
    strncpy(u->nodename, "ish64", sizeof(u->nodename) - 1);
    strncpy(u->release, "6.0", sizeof(u->release) - 1);
    strncpy(u->version, "ish64-dev", sizeof(u->version) - 1);
    strncpy(u->machine, "aarch64", sizeof(u->machine) - 1);
    strncpy(u->domainname, "localdomain", sizeof(u->domainname) - 1);
    return 0;
}
static long sys_mmap(linux_aarch64_regs_t *regs) {
    void *rc = mmap((void *)(uintptr_t)regs->x[0], (size_t)regs->x[1], (int)regs->x[2], (int)regs->x[3], (int)regs->x[4], (off_t)regs->x[5]);
    return (rc == MAP_FAILED) ? neg_errno() : (long)(uintptr_t)rc;
}
static long sys_munmap(linux_aarch64_regs_t *regs) { int rc = munmap((void *)(uintptr_t)regs->x[0], (size_t)regs->x[1]); return (rc < 0) ? neg_errno() : rc; }
static long sys_brk(linux_aarch64_regs_t *regs) { (void)regs; return 0; }
static long sys_exit_common(linux_aarch64_regs_t *regs) { _exit((int)regs->x[0]); }
long linux_aarch64_dispatch_syscall(linux_aarch64_regs_t *regs) {
    if (!regs) return -EINVAL;
    switch (regs->x[8]) {
        case 56: return sys_openat(regs);
        case 57: return sys_close(regs);
        case 63: return sys_read(regs);
        case 64: return sys_write(regs);
        case 93: return sys_exit_common(regs);
        case 94: return sys_exit_common(regs);
        case 160: return sys_uname(regs);
        case 214: return sys_brk(regs);
        case 215: return sys_munmap(regs);
        case 222: return sys_mmap(regs);
        default: return -ENOSYS;
    }
}
