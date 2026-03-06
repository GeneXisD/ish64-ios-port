#ifndef COMPAT_SYS_STATFS_H
#define COMPAT_SYS_STATFS_H

/* macOS/Darwin does not have <sys/statfs.h>,
 * but statfs() and struct statfs live in <sys/mount.h>. */

#include <sys/param.h>
#include <sys/mount.h>

#endif /* COMPAT_SYS_STATFS_H */

