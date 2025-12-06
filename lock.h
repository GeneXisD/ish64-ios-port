// lock.h - kernel lock helpers for iSH64

#ifndef ISH_LOCK_H
#define ISH_LOCK_H

#include "util/sync.h"

/*
 * All lock primitives are defined in util/sync.h:
 *
 *     typedef lock_t;
 *     void  lock_init(lock_t *);
 *     void  lock_destroy(lock_t *);
 *     void  lock(lock_t *);
 *     void  unlock(lock_t *);
 *     bool  trylock(lock_t *);
 *     bool  lock_held(lock_t *);
 *
 * Any file including <lock.h> will get that API.
 */

#endif /* ISH_LOCK_H */

