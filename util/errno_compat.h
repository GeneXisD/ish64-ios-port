#pragma once
#ifndef ERRNO_COMPAT_H
#define ERRNO_COMPAT_H

/*
 * errno compatibility layer
 *
 * IMPORTANT:
 *  - On Apple platforms, ALWAYS use the system errno
 *  - This header is ONLY for non-Apple platforms that lack full errno support
 */

#if defined(__APPLE__)

/* Apple / iOS: use system errno directly */
# include <errno.h>
# include <string.h>

#else  /* !__APPLE__ */

/* Non-Apple platforms */
# include <errno.h>
# include <string.h>

/*
 * Only define missing errno values.
 * DO NOT override existing ones.
 */

# ifndef EINPROGRESS
#  define EINPROGRESS 115
# endif

# ifndef EWOULDBLOCK
#  define EWOULDBLOCK EAGAIN
# endif

# ifndef ECONNREFUSED
#  define ECONNREFUSED 111
# endif

# ifndef EHOSTUNREACH
#  define EHOSTUNREACH 113
# endif

# ifndef ENETUNREACH
#  define ENETUNREACH 101
# endif

#endif /* __APPLE__ */

#endif /* ERRNO_COMPAT_H */
