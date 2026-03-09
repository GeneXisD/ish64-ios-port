#include "backend.h"

#include <errno.h>

static int linux64_x86_64_init(void) {
    return 0;
}

static int linux64_x86_64_load_rootfs(const char *path) {
    (void) path;
    return 0;
}

static int linux64_x86_64_spawn(const char *path, char *const argv[], char *const envp[]) {
    (void) path;
    (void) argv;
    (void) envp;
    errno = ENOSYS;
    return -1;
}

static int linux64_x86_64_step(void) {
    errno = ENOSYS;
    return -1;
}

static int linux64_x86_64_handle_signal(int sig) {
    (void) sig;
    errno = ENOSYS;
    return -1;
}

static void linux64_x86_64_shutdown(void) {
}

static const vm_backend_t BACKEND = {
    .name = "linux64-x86_64",
    .kind = BACKEND_KIND_LINUX64_X86_64,
    .init = linux64_x86_64_init,
    .load_rootfs = linux64_x86_64_load_rootfs,
    .spawn = linux64_x86_64_spawn,
    .step = linux64_x86_64_step,
    .handle_signal = linux64_x86_64_handle_signal,
    .shutdown = linux64_x86_64_shutdown,
};

const vm_backend_t *backend_linux64_x86_64(void) {
    return &BACKEND;
}
