#pragma once

#include <stdlib.h>
#include <stdint.h>

/* Minimal stub structure */
struct asbestos {
    int dummy;
};

/* Allocate */
static inline struct asbestos *asbestos_new(void *m) {
    (void)m;
    return (struct asbestos *)calloc(1, sizeof(struct asbestos));
}

/* Free */
static inline void asbestos_free(struct asbestos *a) {
    free(a);
}

/* Invalidate page (no-op stub) */
static inline void asbestos_invalidate_page(struct asbestos *a, void *p) {
    (void)a;
    (void)p;
}
