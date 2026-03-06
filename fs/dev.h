#ifndef FS_DEV_H
#define FS_DEV_H

#include <sys/types.h>
#include <stdint.h>

/*
 * Keep the fake/Linux-side device encoding stable inside ish:
 * high 16 bits = major
 * low  16 bits = minor
 */
typedef unsigned int dev_t_;

static inline dev_t_ dev_make(dev_t_ major_, dev_t_ minor_) {
    return ((major_ & 0xffffu) << 16) | (minor_ & 0xffffu);
}

static inline dev_t_ dev_major(dev_t_ dev) {
    return (dev >> 16) & 0xffffu;
}

static inline dev_t_ dev_minor(dev_t_ dev) {
    return dev & 0xffffu;
}

static inline dev_t real_dev(dev_t_ dev) {
    return (dev_t) dev;
}

static inline dev_t_ fake_dev(dev_t dev) {
    return (dev_t_) dev;
}

static inline dev_t dev_real_from_fake(dev_t_ dev) {
    return real_dev(dev);
}

static inline dev_t_ dev_fake_from_real(dev_t dev) {
    return fake_dev(dev);
}

/* Darwin / BSD style compatibility typedefs for iPhoneOS SDK headers */
#ifndef __U_INT_DEFINED_ISH64
#define __U_INT_DEFINED_ISH64
typedef unsigned int u_int;
#endif

#ifndef __U_CHAR_DEFINED_ISH64
#define __U_CHAR_DEFINED_ISH64
typedef unsigned char u_char;
#endif

#ifndef __U_SHORT_DEFINED_ISH64
#define __U_SHORT_DEFINED_ISH64
typedef unsigned short u_short;
#endif

struct fd;
struct fd_ops;
struct mount;
struct path;
struct statbuf;
struct poll;

/*
 * Important:
 * fs/fd.h must come AFTER dev_t_ is defined.
 */
#include "fs/fd.h"

/* add this back */
enum dev_kind {
    DEV_BLOCK,
    DEV_CHAR,
};

/* add this back */
int dev_open(int major, int minor, enum dev_kind kind, struct fd *fd);

struct dev_ops {
    const char *name;
    int (*open)(int major, int minor, struct fd *fd);
    int (*getpath)(struct mount *mount, struct path *path, char *buf);
    int (*stat)(struct fd *fd, struct statbuf *stat);
    int (*readlink)(struct mount *mount, struct path *path, char *buf);
    struct fd_ops fd;
};

#endif
