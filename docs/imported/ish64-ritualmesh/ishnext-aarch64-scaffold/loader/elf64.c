#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "linuxu.h"
#include "entry.h"

typedef struct {
    unsigned char e_ident[16];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
} Elf64_Ehdr;

typedef struct {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
} Elf64_Phdr;

#define PT_LOAD 1
#define EM_AARCH64 183

static int to_host_prot(uint32_t pflags) {
    int prot = 0;
    if (pflags & 0x1) prot |= PROT_EXEC;
    if (pflags & 0x2) prot |= PROT_WRITE;
    if (pflags & 0x4) prot |= PROT_READ;
    return prot;
}

static size_t page_size(void) {
    long ps = sysconf(_SC_PAGESIZE);
    return ps > 0 ? (size_t)ps : 4096;
}

static uint64_t page_floor(uint64_t x, uint64_t ps) { return x & ~(ps - 1); }
static uint64_t page_ceil (uint64_t x, uint64_t ps) { return (x + ps - 1) & ~(ps - 1); }

typedef struct { void*sp_base; size_t sp_size; void*sp_top; } stack_image_t;
int build_initial_stack(char **argv, char **envp, uint64_t at_entry, uint64_t at_phdr, uint64_t at_phent, uint64_t at_phnum, size_t host_pagesz, stack_image_t *out);
void dump_initial_stack(stack_image_t *st);

static int g_dryrun = 0;
void elf64_set_dryrun(int yes) { g_dryrun = yes; }

int elf64_load_exec(const char *path) {
    int fd = open(path, O_RDONLY);
    if (fd < 0) { perror("open ELF"); return -1; }

    Elf64_Ehdr eh;
    if (pread(fd, &eh, sizeof(eh), 0) != (ssize_t)sizeof(eh)) {
        perror("read ehdr"); close(fd); return -1;
    }

    if (eh.e_ident[0] != 0x7f || eh.e_ident[1] != 'E' || eh.e_ident[2] != 'L' || eh.e_ident[3] != 'F') {
        fprintf(stderr, "[elf64] Not an ELF: %s\n", path);
        close(fd); return -1;
    }
    if (eh.e_machine != EM_AARCH64) {
        fprintf(stderr, "[elf64] Wrong machine (want AArch64=183), got %u\n", eh.e_machine);
        close(fd); return -1;
    }
    if (eh.e_phentsize != sizeof(Elf64_Phdr)) {
        fprintf(stderr, "[elf64] Unexpected phentsize (%u)\n", eh.e_phentsize);
        close(fd); return -1;
    }

    size_t phdr_bytes = eh.e_phnum * sizeof(Elf64_Phdr);
    Elf64_Phdr *ph = malloc(phdr_bytes);
    if (!ph) { perror("malloc phdr"); close(fd); return -1; }
    if (pread(fd, ph, phdr_bytes, (off_t)eh.e_phoff) != (ssize_t)phdr_bytes) {
        perror("read phdr"); free(ph); close(fd); return -1;
    }

    size_t ps = page_size();
    fprintf(stderr, "[elf64] %s\n", path);
    fprintf(stderr, "  entry = 0x%llx, phnum=%u, pagesize=%zu\n",
            (unsigned long long)eh.e_entry, eh.e_phnum, ps);

    for (int i = 0; i < eh.e_phnum; i++) {
        if (ph[i].p_type != PT_LOAD) continue;
        uint64_t seg_start = page_floor(ph[i].p_vaddr, ps);
        uint64_t seg_end   = page_ceil (ph[i].p_vaddr + ph[i].p_memsz, ps);
        size_t   seg_len   = (size_t)(seg_end - seg_start);
        int prot = to_host_prot(ph[i].p_flags);

        void *p = mmap(NULL, seg_len, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0);
        if (p == MAP_FAILED) { perror("mmap seg"); free(ph); close(fd); return -1; }

        size_t file_off_in_seg = (size_t)(ph[i].p_vaddr - seg_start);
        if (ph[i].p_filesz) {
            if (pread(fd, (char*)p + file_off_in_seg, (size_t)ph[i].p_filesz, (off_t)ph[i].p_offset) != (ssize_t)ph[i].p_filesz) {
                perror("pread seg"); munmap(p, seg_len); free(ph); close(fd); return -1;
            }
        }
        size_t bss_from = file_off_in_seg + (size_t)ph[i].p_filesz;
        size_t bss_len  = (size_t)ph[i].p_memsz > (size_t)ph[i].p_filesz
                        ? (size_t)ph[i].p_memsz - (size_t)ph[i].p_filesz : 0;
        if (bss_len) memset((char*)p + bss_from, 0, bss_len);

        if (mprotect(p, seg_len, prot) != 0) {
            perror("mprotect seg");
        }

        fprintf(stderr, "  PT_LOAD: vaddr=0x%llx filesz=%llu memsz=%llu -> host @%p len=%zu prot=%x\n",
                (unsigned long long)ph[i].p_vaddr,
                (unsigned long long)ph[i].p_filesz,
                (unsigned long long)ph[i].p_memsz,
                p, seg_len, prot);
    }

    // Minimal argv/envp for BusyBox shell
    char *argvv[] = { "busybox", "sh", NULL };
    char *envvv[] = { "PATH=/bin:/sbin:/usr/bin:/usr/sbin", "TERM=xterm", NULL };

    stack_image_t st = {0};
    if (build_initial_stack(argvv, envvv, eh.e_entry, 0, sizeof(Elf64_Phdr), eh.e_phnum, ps, &st) == 0) {
        dump_initial_stack(&st);
        if (!g_dryrun) {
            jump_to_entry(eh.e_entry, st.sp_top);
        } else {
            fprintf(stderr, "[elf64] --dryrun: not jumping to entry\n");
        }
    } else {
        fprintf(stderr, "[elf64] Failed to build initial stack\n");
    }

    free(ph);
    close(fd);
    return 0;
}
