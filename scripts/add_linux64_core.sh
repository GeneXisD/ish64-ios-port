#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(pwd)}"

mkdir -p \
  "$ROOT/loader" \
  "$ROOT/syscall" \
  "$ROOT/backend" \
  "$ROOT/scripts"

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "wrote ${path#$ROOT/}"
}

write_file "$ROOT/loader/linux64_image.h" <<'EOF'
#ifndef ISH_LINUX64_IMAGE_H
#define ISH_LINUX64_IMAGE_H
#include <stdint.h>
#include <stddef.h>
#define LINUX64_MAX_SEGMENTS 16
typedef struct linux64_segment {
    uint64_t vaddr;
    uint64_t memsz;
    uint64_t filesz;
    uint64_t offset;
    uint32_t flags;
} linux64_segment_t;
typedef struct linux64_image {
    uint64_t entry;
    uint16_t machine;
    uint16_t phnum;
    linux64_segment_t segments[LINUX64_MAX_SEGMENTS];
    size_t segment_count;
} linux64_image_t;
int linux64_load_elf_image(const char *path, linux64_image_t *out_image);
#endif
EOF

write_file "$ROOT/loader/linux64_image.c" <<'EOF'
#include "linux64_image.h"
#include <elf.h>
#include <stdio.h>
#include <string.h>
int linux64_load_elf_image(const char *path, linux64_image_t *out_image) {
    if (!path || !out_image) return -1;
    FILE *fp = fopen(path, "rb");
    if (!fp) return -1;
    Elf64_Ehdr eh; memset(&eh, 0, sizeof(eh));
    if (fread(&eh, 1, sizeof(eh), fp) != sizeof(eh)) { fclose(fp); return -1; }
    if (memcmp(eh.e_ident, ELFMAG, SELFMAG) != 0) { fclose(fp); return -1; }
    if (eh.e_ident[EI_CLASS] != ELFCLASS64) { fclose(fp); return -1; }
    if (eh.e_machine != EM_AARCH64 && eh.e_machine != EM_X86_64) { fclose(fp); return -1; }
    if (fseek(fp, (long)eh.e_phoff, SEEK_SET) != 0) { fclose(fp); return -1; }
    memset(out_image, 0, sizeof(*out_image));
    out_image->entry = eh.e_entry;
    out_image->machine = eh.e_machine;
    out_image->phnum = eh.e_phnum;
    for (uint16_t i = 0; i < eh.e_phnum && out_image->segment_count < LINUX64_MAX_SEGMENTS; i++) {
        Elf64_Phdr ph; memset(&ph, 0, sizeof(ph));
        if (fread(&ph, 1, sizeof(ph), fp) != sizeof(ph)) { fclose(fp); return -1; }
        if (ph.p_type != PT_LOAD) continue;
        linux64_segment_t *seg = &out_image->segments[out_image->segment_count++];
        seg->vaddr = ph.p_vaddr;
        seg->memsz = ph.p_memsz;
        seg->filesz = ph.p_filesz;
        seg->offset = ph.p_offset;
        seg->flags = ph.p_flags;
    }
    fclose(fp);
    return 0;
}
EOF

write_file "$ROOT/loader/linux64_stack.h" <<'EOF'
#ifndef ISH_LINUX64_STACK_H
#define ISH_LINUX64_STACK_H
#include <stdint.h>
#include <stddef.h>
typedef struct linux64_stack_layout {
    uint8_t *stack_base;
    size_t stack_size;
    uint64_t guest_sp;
} linux64_stack_layout_t;
int linux64_stack_build(linux64_stack_layout_t *layout, char *const argv[], char *const envp[]);
#endif
EOF

write_file "$ROOT/loader/linux64_stack.c" <<'EOF'
#include "linux64_stack.h"
#include <string.h>
#include <stdint.h>
static size_t count_vec(char *const vec[]) { size_t n = 0; if (!vec) return 0; while (vec[n] != NULL) n++; return n; }
static uint8_t *align_down(uint8_t *p, uintptr_t align) { uintptr_t x = (uintptr_t)p; x &= ~(align - 1); return (uint8_t *)x; }
int linux64_stack_build(linux64_stack_layout_t *layout, char *const argv[], char *const envp[]) {
    if (!layout || !layout->stack_base || layout->stack_size < 4096) return -1;
    uint8_t *base = layout->stack_base;
    uint8_t *sp = base + layout->stack_size;
    size_t argc = count_vec(argv), envc = count_vec(envp);
    uint64_t argv_ptrs[128], envp_ptrs[128];
    if (argc >= 128 || envc >= 128) return -1;
    for (ssize_t i = (ssize_t)envc - 1; i >= 0; i--) { size_t len = strlen(envp[i]) + 1; sp -= len; memcpy(sp, envp[i], len); envp_ptrs[i] = (uint64_t)(uintptr_t)sp; }
    for (ssize_t i = (ssize_t)argc - 1; i >= 0; i--) { size_t len = strlen(argv[i]) + 1; sp -= len; memcpy(sp, argv[i], len); argv_ptrs[i] = (uint64_t)(uintptr_t)sp; }
    sp = align_down(sp, 16);
    sp -= sizeof(uint64_t) * (1 + argc + 1 + envc + 1);
    uint64_t *u64sp = (uint64_t *)sp;
    size_t idx = 0;
    u64sp[idx++] = (uint64_t)argc;
    for (size_t i = 0; i < argc; i++) u64sp[idx++] = argv_ptrs[i];
    u64sp[idx++] = 0;
    for (size_t i = 0; i < envc; i++) u64sp[idx++] = envp_ptrs[i];
    u64sp[idx++] = 0;
    layout->guest_sp = (uint64_t)(uintptr_t)sp;
    return 0;
}
EOF

write_file "$ROOT/syscall/linux_aarch64_syscall.h" <<'EOF'
#ifndef ISH_LINUX_AARCH64_SYSCALL_H
#define ISH_LINUX_AARCH64_SYSCALL_H
#include <stdint.h>
typedef struct linux_aarch64_regs {
    uint64_t x[31];
    uint64_t sp;
    uint64_t pc;
    uint64_t pstate;
} linux_aarch64_regs_t;
long linux_aarch64_dispatch_syscall(linux_aarch64_regs_t *regs);
#endif
EOF

write_file "$ROOT/syscall/linux_aarch64_syscall.c" <<'EOF'
#include "linux_aarch64_syscall.h"
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#ifndef MAP_ANON
#define MAP_ANON MAP_ANONYMOUS
#endif
typedef struct linux_utsname {
    char sysname[65]; char nodename[65]; char release[65];
    char version[65]; char machine[65]; char domainname[65];
} linux_utsname_t;
static long neg_errno(void) { return -errno; }
static int linux_to_host_open_flags(int flags) {
    int out = 0;
    switch (flags & O_ACCMODE) { case O_RDONLY: out |= O_RDONLY; break; case O_WRONLY: out |= O_WRONLY; break; case O_RDWR: out |= O_RDWR; break; default: out |= O_RDONLY; break; }
    if (flags & O_CREAT) out |= O_CREAT;
    if (flags & O_TRUNC) out |= O_TRUNC;
    if (flags & O_APPEND) out |= O_APPEND;
#ifdef O_CLOEXEC
    if (flags & O_CLOEXEC) out |= O_CLOEXEC;
#endif
    return out;
}
static long sys_read(linux_aarch64_regs_t *regs) { ssize_t rc = read((int)regs->x[0], (void *)(uintptr_t)regs->x[1], (size_t)regs->x[2]); return (rc < 0) ? neg_errno() : rc; }
static long sys_write(linux_aarch64_regs_t *regs) { ssize_t rc = write((int)regs->x[0], (const void *)(uintptr_t)regs->x[1], (size_t)regs->x[2]); return (rc < 0) ? neg_errno() : rc; }
static long sys_openat(linux_aarch64_regs_t *regs) { int rc = openat((int)regs->x[0], (const char *)(uintptr_t)regs->x[1], linux_to_host_open_flags((int)regs->x[2]), (int)regs->x[3]); return (rc < 0) ? neg_errno() : rc; }
static long sys_close(linux_aarch64_regs_t *regs) { int rc = close((int)regs->x[0]); return (rc < 0) ? neg_errno() : rc; }
static long sys_uname(linux_aarch64_regs_t *regs) {
    linux_utsname_t *u = (linux_utsname_t *)(uintptr_t)regs->x[0];
    if (!u) return -EFAULT;
    memset(u, 0, sizeof(*u));
    strncpy(u->sysname, "Linux", sizeof(u->sysname) - 1);
    strncpy(u->nodename, "ish64", sizeof(u->nodename) - 1);
    strncpy(u->release, "6.0", sizeof(u->release) - 1);
    strncpy(u->version, "ish64-dev", sizeof(u->version) - 1);
    strncpy(u->machine, "aarch64", sizeof(u->machine) - 1);
    strncpy(u->domainname, "localdomain", sizeof(u->domainname) - 1);
    return 0;
}
static long sys_mmap(linux_aarch64_regs_t *regs) {
    void *rc = mmap((void *)(uintptr_t)regs->x[0], (size_t)regs->x[1], (int)regs->x[2], (int)regs->x[3], (int)regs->x[4], (off_t)regs->x[5]);
    return (rc == MAP_FAILED) ? neg_errno() : (long)(uintptr_t)rc;
}
static long sys_munmap(linux_aarch64_regs_t *regs) { int rc = munmap((void *)(uintptr_t)regs->x[0], (size_t)regs->x[1]); return (rc < 0) ? neg_errno() : rc; }
static long sys_brk(linux_aarch64_regs_t *regs) { (void)regs; return 0; }
static long sys_exit_common(linux_aarch64_regs_t *regs) { _exit((int)regs->x[0]); }
long linux_aarch64_dispatch_syscall(linux_aarch64_regs_t *regs) {
    if (!regs) return -EINVAL;
    switch (regs->x[8]) {
        case 56: return sys_openat(regs);
        case 57: return sys_close(regs);
        case 63: return sys_read(regs);
        case 64: return sys_write(regs);
        case 93: return sys_exit_common(regs);
        case 94: return sys_exit_common(regs);
        case 160: return sys_uname(regs);
        case 214: return sys_brk(regs);
        case 215: return sys_munmap(regs);
        case 222: return sys_mmap(regs);
        default: return -ENOSYS;
    }
}
EOF

write_file "$ROOT/backend/backend_linux64_aarch64.c" <<'EOF'
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
EOF

cat <<'EOF'
Done.

Now add these new .c files to your Xcode target(s):
- loader/linux64_image.c
- loader/linux64_stack.c
- syscall/linux_aarch64_syscall.c
- backend/backend_linux64_aarch64.c
EOF
