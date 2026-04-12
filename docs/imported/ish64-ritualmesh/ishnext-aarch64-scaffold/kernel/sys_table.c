#include <stdio.h>
#include "linuxu.h"
#include "sysnr_aarch64.h"

// Forward decls of handlers
long sys_read(linux_regs_t*), sys_write(linux_regs_t*), sys_openat(linux_regs_t*);
long sys_close(linux_regs_t*), sys_fstat(linux_regs_t*), sys_lseek(linux_regs_t*);
long sys_mmap(linux_regs_t*), sys_mprotect(linux_regs_t*), sys_brk(linux_regs_t*);
long sys_exit(linux_regs_t*);

static long sys_enosys(linux_regs_t *r) { (void)r; return -LINUX_ENOSYS; }

typedef long (*sysfn_t)(linux_regs_t*);
static sysfn_t sys_tbl[512] = {0};

__attribute__((constructor))
static void sys_tbl_init(void) {
    // Fill with ENOSYS
    for (int i=0;i<512;i++) sys_tbl[i]=sys_enosys;
    // M0 mappings
    sys_tbl[__NR_read]     = sys_read;
    sys_tbl[__NR_write]    = sys_write;
    sys_tbl[__NR_openat]   = sys_openat;
    sys_tbl[__NR_close]    = sys_close;
    sys_tbl[__NR_fstat]    = sys_fstat;
    sys_tbl[__NR_lseek]    = sys_lseek;
    sys_tbl[__NR_mmap]     = sys_mmap;
    sys_tbl[__NR_mprotect] = sys_mprotect;
    sys_tbl[__NR_brk]      = sys_brk;
    sys_tbl[__NR_exit]     = sys_exit;
}

long linux_syscall_entry(linux_regs_t *r) {
    uint64_t no = r->x8;
    if (no < 512 && sys_tbl[no]) return sys_tbl[no](r);
    return -LINUX_ENOSYS;
}
