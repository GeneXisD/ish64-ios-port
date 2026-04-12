#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>
#include "linuxu.h"
#include "errno_linux.h"

long sys_mmap(linux_regs_t *r) {
    void *addr = (void*)r->x[0];
    size_t len = (size_t)r->x[1];
    int prot = (int)r->x[2];
    int flags = (int)r->x[3];
    int fd = (int)r->x[4];
    off_t off = (off_t)r->x[5];
    void *p = mmap(addr, len, prot, flags, fd, off);
    if (p == MAP_FAILED) return linux_err(errno);
    return (long)p;
}

long sys_mprotect(linux_regs_t *r) {
    void *addr = (void*)r->x[0];
    size_t len = (size_t)r->x[1];
    int prot = (int)r->x[2];
    int rc = mprotect(addr, len, prot);
    if (rc < 0) return linux_err(errno);
    return 0;
}

long sys_brk(linux_regs_t *r) {
    (void)r;
    // Stub: report ENOSYS for now
    return -38;
}
