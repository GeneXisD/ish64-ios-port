#include "backend.h"

#include <errno.h>

static int linux64_stub_init(void) {
    return 0;
}

static int linux64_stub_load_rootfs(const char *path) {
    (void) path;
    return 0;
}

static int linux64_stub_spawn(const char *path, char *const argv[], char *const envp[]) {
    (void) path;
    (void) argv;
    (void) envp;
    errno = ENOSYS;
    return -1;
}

static int linux64_stub_step(void) {
    errno = ENOSYS;
    return -1;
}

static int linux64_stub_handle_signal(int sig) {
    (void) sig;
    errno = ENOSYS;
    return -1;
}

static void linux64_stub_shutdown(void) {
}

static const vm_backend_t BACKEND = {
    .name = "linux64-stub",
    .kind = BACKEND_KIND_LINUX64_STUB,
    .init = linux64_stub_init,
    .load_rootfs = linux64_stub_load_rootfs,
    .spawn = linux64_stub_spawn,
    .step = linux64_stub_step,
    .handle_signal = linux64_stub_handle_signal,
    .shutdown = linux64_stub_shutdown,
};

const vm_backend_t *backend_linux64_stub(void) {
    return &BACKEND;
}
