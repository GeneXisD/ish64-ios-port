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
