#include "elf64.h"

#include <elf.h>
#include <stdio.h>
#include <string.h>

int elf64_load_image(const char *path, elf64_image_t *out_image) {
    if (path == NULL || out_image == NULL)
        return -1;

    FILE *fp = fopen(path, "rb");
    if (!fp)
        return -1;

    Elf64_Ehdr eh;
    memset(&eh, 0, sizeof(eh));

    if (fread(&eh, 1, sizeof(eh), fp) != sizeof(eh)) {
        fclose(fp);
        return -1;
    }

    fclose(fp);

    if (memcmp(eh.e_ident, ELFMAG, SELFMAG) != 0)
        return -1;
    if (eh.e_ident[EI_CLASS] != ELFCLASS64)
        return -1;

    memset(out_image, 0, sizeof(*out_image));
    out_image->entry = eh.e_entry;
    out_image->phoff = eh.e_phoff;
    out_image->phnum = eh.e_phnum;
    out_image->machine = eh.e_machine;
    return 0;
}
