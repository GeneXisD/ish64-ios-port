/* compat/ios_fixes.h
 *
 * Centralized portability fixes for iOS/clang builds:
 * - common system headers needed by slirp/tinyemu sources
 * - safe container_of guard (only define if not already defined)
 */
#ifndef COMPAT_IOS_FIXES_H
#define COMPAT_IOS_FIXES_H

#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stddef.h> /* offsetof, ptrdiff_t */

#ifndef container_of
#ifndef container_of
#ifndef container_of
#define container_of() \
    ((type *) ((char *)(ptr) - offsetof(type, member)))
#endif

#endif

#endif

#endif /* COMPAT_IOS_FIXES_H */

