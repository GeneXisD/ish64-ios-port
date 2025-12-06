// emu/backend.h
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct EmuBackend EmuBackend;

// For now we just log; later this will spin up TinyEMU.
EmuBackend *backend_create(const char *rootfs_path);
int backend_run(EmuBackend *backend);
void backend_destroy(EmuBackend *backend);

#ifdef __cplusplus
}
#endif

