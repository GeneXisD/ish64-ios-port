#include "backend.h"
#include "../loader/linux64_image.h"
#include "../loader/linux64_stack.h"
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct linux64_aarch64_state {
    char rootfs_path[1024];
    linux64_image_t image;
    linux64_stack_layout_t stack;
    uint8_t *stack_mem;
} linux64_aarch64_state_t;
static linux64_aarch64_state_t g_state;
static int linux64_aarch64_init(void) { memset(&g_state, 0, sizeof(g_state)); return 0; }
static int linux64_aarch64_load_rootfs(const char *path) {
    if (!path) { errno = EINVAL; return -1; }
    snprintf(g_state.rootfs_path, sizeof(g_state.rootfs_path), "%s", path);
    return 0;
}
static int linux64_aarch64_spawn(const char *path, char *const argv[], char *const envp[]) {
    if (!path) { errno = EINVAL; return -1; }
    if (linux64_load_elf_image(path, &g_state.image) != 0) { errno = ENOEXEC; return -1; }
    g_state.stack_mem = malloc(1024 * 1024);
    if (!g_state.stack_mem) { errno = ENOMEM; return -1; }
    g_state.stack.stack_base = g_state.stack_mem;
    g_state.stack.stack_size = 1024 * 1024;
    g_state.stack.guest_sp = 0;
    if (linux64_stack_build(&g_state.stack, argv, envp) != 0) {
        free(g_state.stack_mem); g_state.stack_mem = NULL; errno = EFAULT; return -1;
    }
    fprintf(stderr, "[linux64-aarch64] loaded ELF entry=0x%llx segments=%zu sp=0x%llx\n",
            (unsigned long long)g_state.image.entry,
            g_state.image.segment_count,
            (unsigned long long)g_state.stack.guest_sp);
    errno = ENOSYS;
    return -1;
}
static int linux64_aarch64_step(void) { errno = ENOSYS; return -1; }
static int linux64_aarch64_handle_signal(int sig) { (void)sig; errno = ENOSYS; return -1; }
static void linux64_aarch64_shutdown(void) {
    free(g_state.stack_mem);
    g_state.stack_mem = NULL;
    memset(&g_state.image, 0, sizeof(g_state.image));
    memset(&g_state.stack, 0, sizeof(g_state.stack));
}
static const vm_backend_t BACKEND = {
    .name = "linux64-aarch64",
    .kind = BACKEND_KIND_LINUX64_AARCH64,
    .init = linux64_aarch64_init,
    .load_rootfs = linux64_aarch64_load_rootfs,
    .spawn = linux64_aarch64_spawn,
    .step = linux64_aarch64_step,
    .handle_signal = linux64_aarch64_handle_signal,
    .shutdown = linux64_aarch64_shutdown,
};
const vm_backend_t *backend_linux64_aarch64(void) { return &BACKEND; }
