#include <stdlib.h>
#include <stdint.h>

/* ================= CPU ================= */
void cpu_run_to_interrupt() {}

/* ================= MEMORY ================= */
void *mm_new() { return NULL; }
void mm_copy() {}
void mm_release() {}
void mm_retain() {}

/* ================= LOCKS ================= */
void cond_init() {}
void cond_destroy() {}

void read_wrlock() {}
void read_wrunlock() {}
void write_wrlock() {}
void write_wrunlock() {}

void wrlock_init() {}
void wrlock_destroy() {}

/* ================= SIGNAL ================= */
void sigusr1_handler() {}
void wait_for_ignore_signals() {}

/* ================= LOG ================= */
void log_line(const char *line) { (void)line; }

/* ================= REAL FS ================= */
void *realfs;

int realfs_close() { return -1; }
int realfs_read() { return -1; }
int realfs_write() { return -1; }
int realfs_poll() { return -1; }
int realfs_ioctl() { return -1; }
int realfs_ioctl_size() { return -1; }
int realfs_getflags() { return -1; }
int realfs_setflags() { return -1; }
int realfs_flock() { return -1; }
int realfs_statfs() { return -1; }
int realfs_utime() { return -1; }
int realfs_getpath() { return -1; }

void *realfs_fdops;

/* ================= SYS STUBS ================= */
int sys_brk() { return -1; }
int sys_mmap() { return -1; }
int sys_mmap2() { return -1; }
int sys_munmap() { return -1; }
int sys_mprotect() { return -1; }
int sys_mremap() { return -1; }
int sys_msync() { return -1; }
int sys_madvise() { return -1; }
int sys_mbind() { return -1; }
int sys_mlock() { return -1; }
