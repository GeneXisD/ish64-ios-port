#include <stdio.h>
#include <stdint.h>
#include "entry.h"

void jump_to_entry(uint64_t entry, void *initial_sp) {
#if defined(__aarch64__)
    fprintf(stderr, "[entry] (arm64) would jump to 0x%llx with SP=%p\n",
            (unsigned long long)entry, initial_sp);
#else
    (void)entry; (void)initial_sp;
    fprintf(stderr, "[entry] (Intel host) jump suppressed.\n");
#endif
}
