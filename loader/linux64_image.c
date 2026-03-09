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
