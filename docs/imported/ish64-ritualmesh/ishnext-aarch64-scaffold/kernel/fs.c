#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include "linuxu.h"
#include "errno_linux.h"

long sys_openat(linux_regs_t *r) {
    int dirfd = (int)r->x[0];
    const char *path = (const char*)r->x[1];
    int flags = (int)r->x[2];
    int mode = (int)r->x[3];
    int fd = openat(dirfd, path, flags, mode);
    if (fd < 0) return linux_err(errno);
    return fd;
}

long sys_close(linux_regs_t *r) {
    int fd = (int)r->x[0];
    int rc = close(fd);
    if (rc < 0) return linux_err(errno);
    return 0;
}

long sys_fstat(linux_regs_t *r) {
    int fd = (int)r->x[0];
    struct stat st;
    if (fstat(fd, &st) < 0) return linux_err(errno);
    // NOTE: You must translate struct stat -> Linux stat64. Stub: report success only.
    return 0;
}

long sys_lseek(linux_regs_t *r) {
    int fd = (int)r->x[0];
    off_t off = (off_t)r->x[1];
    int wh = (int)r->x[2];
    off_t rcv = lseek(fd, off, wh);
    if (rcv < 0) return linux_err(errno);
    return (long)rcv;
}
