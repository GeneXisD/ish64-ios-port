#ifndef ISH_ELF64_H
#define ISH_ELF64_H

#include <stdint.h>

typedef struct elf64_image {
    uint64_t entry;
    uint64_t phoff;
    uint16_t phnum;
    uint16_t machine;
} elf64_image_t;

int elf64_load_image(const char *path, elf64_image_t *out_image);

#endif
