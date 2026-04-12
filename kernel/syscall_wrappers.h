#ifndef SYSCALL_WRAPPERS_H
#define SYSCALL_WRAPPERS_H

#include "kernel/calls.h"

// Wrapper macro: 6 args, ignore extras
#define WRAP_SYSCALL(name) \
static int syscall_##name##_wrapper(unsigned int a, unsigned int b, unsigned int c, \
                                   unsigned int d, unsigned int e, unsigned int f) { \
    return name(a,b,c,d,e,f); \
}

#endif // SYSCALL_WRAPPERS_H
