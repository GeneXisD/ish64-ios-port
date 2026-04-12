#include <stdlib.h>

void *mm_new() { return malloc(1); }
void mm_release(void *m) { free(m); }
void mm_retain(void *m) {}
void mm_copy(void *dst, void *src) {}
