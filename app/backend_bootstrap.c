#include "../backend/backend.h"
#include "../rootfs/rootfs_manifest.h"
#include "backend/backend.h"

void backend_bootstrap(void) {
    const vm_backend_t *backend = backend_select("ish-x86");
    backend_activate(backend);
}
int ish_backend_bootstrap(const char *rootfs_dir) {
    rootfs_manifest_t manifest;
    if (rootfs_manifest_load(rootfs_dir, &manifest) != 0)
        return -1;

    const vm_backend_t *backend = rootfs_manifest_select_backend(&manifest);
    if (backend_set_active(backend) != 0)
        return -1;

    if (backend_init_active() != 0)
        return -1;

    if (backend_load_rootfs_active(rootfs_dir) != 0)
        return -1;

    return 0;
}
