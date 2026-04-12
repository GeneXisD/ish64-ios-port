#include <time.h>
#include <sys/time.h>
#include <errno.h>
#include "linuxu.h"
#include "errno_linux.h"

long sys_nanosleep(linux_regs_t *r) {
    const struct timespec *req = (const struct timespec*)r->x[0];
    struct timespec rem = {0};
    int rc = nanosleep(req, &rem);
    if (rc < 0) return linux_err(errno);
    return 0;
}

// Extend with clock_gettime/gettimeofday mapping as needed.
