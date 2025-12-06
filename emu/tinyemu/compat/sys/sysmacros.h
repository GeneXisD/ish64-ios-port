#ifndef COMPAT_SYS_SYSMACROS_H
#define COMPAT_SYS_SYSMACROS_H

/* macOS/Darwin shim for Linux <sys/sysmacros.h> */

#include <sys/types.h>

#ifndef major
#define major(dev)  ((int)(((dev) >> 24) & 0xff))
#endif

#ifndef minor
#define minor(dev)  ((int)((dev) & 0xffffff))
#endif

#ifndef makedev
#define makedev(maj, min) ((((maj) & 0xff) << 24) | ((min) & 0xffffff))
#endif

#endif /* COMPAT_SYS_SYSMACROS_H */

