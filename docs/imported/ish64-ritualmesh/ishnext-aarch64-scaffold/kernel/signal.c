#include <unistd.h>
#include "linuxu.h"
long sys_exit(linux_regs_t *r) {
    int code = (int)r->x[0];
    _exit(code);
    return 0;
}
