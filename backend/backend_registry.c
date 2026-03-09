#include "backend.h"

#include <stddef.h>
#include <string.h>

static const vm_backend_t *g_active_backend = NULL;

static const vm_backend_t *all_backends[] = {
    NULL,
    NULL,
    NULL,
    NULL,
};

static void backend_registry_bootstrap(void) {
    if (all_backends[0] != NULL)
        return;

    all_backends[0] = backend_ish_x86();
    all_backends[1] = backend_linux64_stub();
    all_backends[2] = backend_linux64_aarch64();
    all_backends[3] = backend_linux64_x86_64();

    if (g_active_backend == NULL)
        g_active_backend = all_backends[0];
}

const vm_backend_t *backend_get_default(void) {
    backend_registry_bootstrap();
    return all_backends[0];
}

const vm_backend_t *backend_get_by_kind(backend_kind_t kind) {
    backend_registry_bootstrap();

    for (size_t i = 0; i < sizeof(all_backends) / sizeof(all_backends[0]); i++) {
        if (all_backends[i] != NULL && all_backends[i]->kind == kind)
            return all_backends[i];
    }
    return NULL;
}

const vm_backend_t *backend_get_by_name(const char *name) {
    backend_registry_bootstrap();
    if (name == NULL)
        return NULL;

    for (size_t i = 0; i < sizeof(all_backends) / sizeof(all_backends[0]); i++) {
        if (all_backends[i] != NULL && all_backends[i]->name != NULL &&
            strcmp(all_backends[i]->name, name) == 0)
            return all_backends[i];
    }
    return NULL;
}

int backend_set_active(const vm_backend_t *backend) {
    backend_registry_bootstrap();
    if (backend == NULL)
        return -1;
    g_active_backend = backend;
    return 0;
}

const vm_backend_t *backend_get_active(void) {
    backend_registry_bootstrap();
    return g_active_backend;
}

int backend_init_active(void) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->init) ? b->init() : -1;
}

int backend_load_rootfs_active(const char *path) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->load_rootfs) ? b->load_rootfs(path) : -1;
}

int backend_spawn_active(const char *path, char *const argv[], char *const envp[]) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->spawn) ? b->spawn(path, argv, envp) : -1;
}

int backend_step_active(void) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->step) ? b->step() : -1;
}

int backend_handle_signal_active(int sig) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->handle_signal) ? b->handle_signal(sig) : -1;
}

void backend_shutdown_active(void) {
    const vm_backend_t *b = backend_get_active();
    if (b && b->shutdown)
        b->shutdown();
}
