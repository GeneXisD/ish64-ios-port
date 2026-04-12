#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include "linuxu.h"
#include "errno_linux.h"

// Minimal M0 syscalls — for host dev only. These simply proxy to POSIX where possible.
// NOTE: This is not the final Darwin mapping; it's a bring-up layer.

long sys_read(linux_regs_t *r) {
    int fd = (int)r->x[0];
    void *buf = (void*)r->x[1];
    size_t sz = (size_t)r->x[2];
    ssize_t n = read(fd, buf, sz);
    if (n < 0) return linux_err(errno);
    return (long)n;
}

long sys_write(linux_regs_t *r) {
    int fd = (int)r->x[0];
    const void *buf = (const void*)r->x[1];
    size_t sz = (size_t)r->x[2];
    ssize_t n = write(fd, buf, sz);
    if (n < 0) return linux_err(errno);
    return (long)n;
}
