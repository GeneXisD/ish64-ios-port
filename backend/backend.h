#ifndef ISH_BACKEND_H
#define ISH_BACKEND_H

#ifdef __cplusplus
extern "C" {
#endif

struct vm_backend;

typedef enum {
    BACKEND_KIND_ISH_X86 = 0,
    BACKEND_KIND_LINUX64_STUB = 1,
    BACKEND_KIND_LINUX64_AARCH64 = 2,
    BACKEND_KIND_LINUX64_X86_64 = 3,
} backend_kind_t;

typedef struct vm_backend {
    const char *name;
    backend_kind_t kind;

    int (*init)(void);
    int (*load_rootfs)(const char *path);
    int (*spawn)(const char *path, char *const argv[], char *const envp[]);
    int (*step)(void);
    int (*handle_signal)(int sig);
    void (*shutdown)(void);
} vm_backend_t;

const vm_backend_t *backend_get_default(void);
const vm_backend_t *backend_get_by_kind(backend_kind_t kind);
const vm_backend_t *backend_get_by_name(const char *name);

int backend_set_active(const vm_backend_t *backend);
const vm_backend_t *backend_get_active(void);

int backend_init_active(void);
int backend_load_rootfs_active(const char *path);
int backend_spawn_active(const char *path, char *const argv[], char *const envp[]);
int backend_step_active(void);
int backend_handle_signal_active(int sig);
void backend_shutdown_active(void);

const vm_backend_t *backend_ish_x86(void);
const vm_backend_t *backend_linux64_stub(void);
const vm_backend_t *backend_linux64_aarch64(void);
const vm_backend_t *backend_linux64_x86_64(void);

#ifdef __cplusplus
}
#endif

#endif
