#ifndef ASBESTOS_H
#define ASBESTOS_H
#include <stdlib.h>
struct asbestos { int dummy; };
static inline struct asbestos* asbestos_new(void *m){ return calloc(1,sizeof(struct asbestos)); }
static inline void asbestos_free(struct asbestos *a){ free(a); }
static inline void asbestos_invalidate_page(struct asbestos *a, void *p){}
#endif
