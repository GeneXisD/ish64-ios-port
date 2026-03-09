#include "rootfs_manifest.h"

#include <stdio.h>
#include <string.h>

int rootfs_manifest_load(const char *rootfs_dir, rootfs_manifest_t *out_manifest) {
    (void) rootfs_dir;
    if (out_manifest == NULL)
        return -1;

    memset(out_manifest, 0, sizeof(*out_manifest));
    snprintf(out_manifest->name, sizeof(out_manifest->name), "%s", "Default RootFS");
    snprintf(out_manifest->arch, sizeof(out_manifest->arch), "%s", "x86");
    snprintf(out_manifest->abi, sizeof(out_manifest->abi), "%s", "linux");
    snprintf(out_manifest->backend_name, sizeof(out_manifest->backend_name), "%s", "ish-x86");
    snprintf(out_manifest->init_path, sizeof(out_manifest->init_path), "%s", "/bin/sh");
    return 0;
}

const vm_backend_t *rootfs_manifest_select_backend(const rootfs_manifest_t *manifest) {
    if (manifest == NULL)
        return backend_get_default();

    const vm_backend_t *backend = backend_get_by_name(manifest->backend_name);
    return backend ? backend : backend_get_default();
}
