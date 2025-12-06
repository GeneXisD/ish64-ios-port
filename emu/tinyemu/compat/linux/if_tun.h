#ifndef COMPAT_LINUX_IF_TUN_H
#define COMPAT_LINUX_IF_TUN_H

/* macOS/Darwin: use system net/if.h struct ifreq,
 * just provide the Linux-style flag names and ioctl. */

#include <net/if.h>

#ifndef IFF_TUN
#define IFF_TUN 0x0001
#endif

#ifndef IFF_TAP
#define IFF_TAP 0x0002
#endif

#ifndef IFF_NO_PI
#define IFF_NO_PI 0x1000
#endif

#ifndef TUNSETIFF
#define TUNSETIFF 0x400454ca
#endif

#endif /* COMPAT_LINUX_IF_TUN_H */

