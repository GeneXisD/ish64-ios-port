#include <errno.h>
#include <unistd.h>
#include "util/sync.h"
#include "sync.h"

#ifndef LOCK_INITIALIZER
#   include <pthread.h>
    // fallback: assume lock_t is a pthread_mutex_t or struct wrapper
#   define LOCK_INITIALIZER PTHREAD_MUTEX_INITIALIZER
#endif
static lock_t fchdir_lock = LOCK_INITIALIZER;

void lock_fchdir(int dirfd) {
    lock(&fchdir_lock);
    fchdir(dirfd);
}

void unlock_fchdir() {
    unlock(&fchdir_lock);
}
