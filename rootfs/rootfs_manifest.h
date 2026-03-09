#ifndef ISH_ROOTFS_MANIFEST_H
#define ISH_ROOTFS_MANIFEST_H

#include "../backend/backend.h"

typedef struct rootfs_manifest {
    char name[64];
    char arch[32];
    char abi[32];
    char backend_name[64];
    char init_path[256];
} rootfs_manifest_t;

int rootfs_manifest_load(const char *rootfs_dir, rootfs_manifest_t *out_manifest);
const vm_backend_t *rootfs_manifest_select_backend(const rootfs_manifest_t *manifest);

#endif
