// util/sync.h - pthread-based lock primitives for iSH64

#ifndef UTIL_SYNC_H
#define UTIL_SYNC_H

#include <stdbool.h>
#include <pthread.h>
typedef pthread_cond_t cond_t;
/*
 * Simple mutex wrapper.
 *
 * If you want a more advanced implementation later (spinlocks, futex-based,
 * custom assertions, etc.), you can swap it in behind this API without
 * touching callers.
 */

typedef pthread_mutex_t lock_t;

int wait_for(cond_t *cond, lock_t *lock, struct timespec *timeout);
void notify(cond_t *cond);
void cond_init(cond_t *cond);
void cond_destroy(cond_t *cond);

static inline void lock_init(lock_t *lock) {
    pthread_mutex_init(lock, NULL);
}

static inline void lock_destroy(lock_t *lock) {
    pthread_mutex_destroy(lock);
}

static inline void lock(lock_t *lock) {
    pthread_mutex_lock(lock);
}

static inline void unlock(lock_t *lock) {
    pthread_mutex_unlock(lock);
}

static inline bool trylock(lock_t *lock) {
    return pthread_mutex_trylock(lock) == 0;
}

/*
 * We can’t portably query ownership with plain pthread mutexes.
 * If you need this later, you can switch to error-checking mutexes or
 * add debugging-only tracking around these calls.
 */
static inline bool lock_held(lock_t *lock) {
    (void)lock;
    return false;
}

#endif /* UTIL_SYNC_H */

