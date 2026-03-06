/* ios_fixes.h - minimal compatibility shims for iOS build */
/* Created automatically. Backups: ios_fixes.h.bak */

#ifndef EMU_COMPAT_IOS_FIXES_H
#define EMU_COMPAT_IOS_FIXES_H

/* common system includes needed by slirp/socket code */
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

/* Ensure common error macros available */
#ifndef EWOULDBLOCK
# include <errno.h>
#endif

/* If Slirp type not available, forward-declare to avoid compile-time unknown-type errors.
   Real implementation defines struct Slirp in slirp sources. */
#ifndef __SLIRP_FWD_DECL
#define __SLIRP_FWD_DECL
typedef struct Slirp Slirp;
#endif

#endif /* EMU_COMPAT_IOS_FIXES_H */
