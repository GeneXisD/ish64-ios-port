#ifdef __APPLE__
#include <sys/poll.h>
#include <sys/file.h>
#define MMAP_PRIVATE MAP_PRIVATE
#define MMAP_SHARED  MAP_SHARED
#define LOCK_SH_ LOCK_SH
#define LOCK_EX_ LOCK_EX
#define LOCK_UN_ LOCK_UN
#define LOCK_NB_ LOCK_NB
#else
typedef unsigned long int nfds_t;
struct pollfd {
    int fd;
    short events;
    short revents;
};
#endif

#include "fs.h"

/* Rest of your original fs/real.c contents go here... */
