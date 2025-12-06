// emu/backend_tinyemu.c
#include <stdio.h>
#include <stdlib.h>
#include "backend.h"

struct EmuBackend {
    const char *rootfs;
};

EmuBackend *backend_create(const char *rootfs_path) {
    EmuBackend *b = calloc(1, sizeof(*b));
    if (!b) return NULL;
    b->rootfs = rootfs_path;
    fprintf(stderr, "[TinyEMU] backend_create(%s)\n",
            rootfs_path ? rootfs_path : "(null)");
    return b;
}

int backend_run(EmuBackend *backend) {
    fprintf(stderr, "[TinyEMU] backend_run stub reached.\n");
    // later: TinyEMU VM init/run here
    return 0;
}

void backend_destroy(EmuBackend *backend) {
    if (!backend) return;
    fprintf(stderr, "[TinyEMU] backend_destroy\n");
    free(backend);
}

