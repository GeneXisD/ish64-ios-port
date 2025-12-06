// util/sync.c

#include "sync.h"
#include <pthread.h>
#include <time.h>

/*
 * Thin wrappers around pthread condition waits so the rest of the kernel
 * can stay in terms of cond_t / lock_t.
 * Adjust the return-value mapping later if you want Linux-style -E* codes;
 * for now we just bubble up the pthread error code.
 */

static inline int cond_wait(cond_t *cond, lock_t *lock) {
    return pthread_cond_wait(cond, lock);
}

static inline int cond_timedwait(cond_t *cond, lock_t *lock,
                                 const struct timespec *timeout) {
    return pthread_cond_timedwait(cond, lock, timeout);
}

int wait_for(cond_t *cond, lock_t *lock, struct timespec *timeout) {
    int err;
    if (timeout != NULL)
        err = cond_timedwait(cond, lock, timeout);
    else
        err = cond_wait(cond, lock);
    return err;
}

void notify(cond_t *cond) {
    // wake *all* waiters – matches how it's used for broadcast-style events
    pthread_cond_broadcast(cond);
}

