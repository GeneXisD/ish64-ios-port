#include <stdio.h>
#include "linuxu.h"

// Stubs for /proc emulation will live here.
void proc_stub_dump(void) {
    fprintf(stderr, "[proc] /proc stubs active (M0)\n");
}
