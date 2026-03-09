#include "backend.h"

/*
 * Adapter layer for the current iSH execution core.
 * Replace the TODO sections with calls into the existing emulator path.
 */

static int ish_x86_init(void) {
    return 0;
}

static int ish_x86_load_rootfs(const char *path) {
    (void) path;
    return 0;
}

static int ish_x86_spawn(const char *path, char *const argv[], char *const envp[]) {
    (void) path;
    (void) argv;
    (void) envp;
    return 0;
}

static int ish_x86_step(void) {
    return 0;
}

static int ish_x86_handle_signal(int sig) {
    (void) sig;
    return 0;
}

static void ish_x86_shutdown(void) {
}

static const vm_backend_t BACKEND = {
    .name = "ish-x86",
    .kind = BACKEND_KIND_ISH_X86,
    .init = ish_x86_init,
    .load_rootfs = ish_x86_load_rootfs,
    .spawn = ish_x86_spawn,
    .step = ish_x86_step,
    .handle_signal = ish_x86_handle_signal,
    .shutdown = ish_x86_shutdown,
};

const vm_backend_t *backend_ish_x86(void) {
    return &BACKEND;
}
