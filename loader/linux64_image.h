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
