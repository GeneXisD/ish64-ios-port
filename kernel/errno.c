#include "debug.h"
#include "kernel/task.h"
#include "kernel/signal.h"
#include "kernel/errno.h"
#include "misc.h"
#include "debug.h"

// Needed for ENOENT, ESRCH, EINTR, EIO, ENXIO, E2BIG, ENOEXEC, EBADF, ...
#include <errno.h>
extern int errno;

#ifndef EPERM
#define EPERM 1
#endif

#ifndef ENOENT
#define ENOENT 2
#endif
#ifndef ESRCH
#define ESRCH 3
#endif
#ifndef EINTR
#define EINTR 4
#endif
#ifndef EIO
#define EIO 5
#endif
#ifndef ENXIO
#define ENXIO 6
#endif
#ifndef E2BIG
#define E2BIG 7
#endif
#ifndef ENOEXEC
#define ENOEXEC 8
#endif
#ifndef EBADF
#define EBADF 9
#endif
#ifndef ECHILD
#define ECHILD 10
#endif
#ifndef EAGAIN
#define EAGAIN 11
#endif
#ifndef ENOMEM
#define ENOMEM 12
#endif
#ifndef EACCES
#define EACCES 13
#endif
#ifndef EFAULT
#define EFAULT 14
#endif
#ifndef ENOTBLK
#define ENOTBLK 15
#endif
#ifndef EBUSY
#define EBUSY 16
#endif
#ifndef EEXIST
#define EEXIST 17
#endif
#ifndef EXDEV
#define EXDEV 18
#endif
#ifndef ENODEV
#define ENODEV 19
#endif
#ifndef ENOTDIR
#define ENOTDIR 20
#endif
#ifndef EISDIR
#define EISDIR 21
#endif

#ifndef ENOSTR
#define ENOSTR 60
#endif
#ifndef ENODATA
#define ENODATA 61
#endif
#ifndef ETIME
#define ETIME 62
#endif
#ifndef ENOSR
#define ENOSR 63
#endif
#ifndef EREMOTE
#define EREMOTE 66
#endif
#ifndef ENOLINK
#define ENOLINK 67
#endif
#ifndef EPROTO
#define EPROTO 71
#endif
#ifndef EMULTIHOP
#define EMULTIHOP 72
#endif
#ifndef EBADMSG
#define EBADMSG 74
#endif
#ifndef EOVERFLOW
#define EOVERFLOW 75
#endif
#ifndef EILSEQ
#define EILSEQ 84
#endif
#ifndef EUSERS
#define EUSERS 87
#endif
#ifndef ENOTSOCK
#define ENOTSOCK 88
#endif
#ifndef EDESTADDRREQ
#define EDESTADDRREQ 89
#endif
#ifndef EMSGSIZE
#define EMSGSIZE 90
#endif
#ifndef EPROTOTYPE
#define EPROTOTYPE 91
#endif
#ifndef ENOPROTOOPT
#define ENOPROTOOPT 92
#endif
#ifndef EPROTONOSUPPORT
#define EPROTONOSUPPORT 93
#endif
#ifndef ESOCKTNOSUPPORT
#define ESOCKTNOSUPPORT 94
#endif
#ifndef EOPNOTSUPP
#define EOPNOTSUPP 95
#endif
#ifndef ENOTSUP
#define ENOTSUP 95
#endif
#ifndef EPFNOSUPPORT
#define EPFNOSUPPORT 96
#endif
#ifndef EAFNOSUPPORT
#define EAFNOSUPPORT 97
#endif
#ifndef EADDRINUSE
#define EADDRINUSE 98
#endif
#ifndef EADDRNOTAVAIL
#define EADDRNOTAVAIL 99
#endif
#ifndef ENETDOWN
#define ENETDOWN 100
#endif
#ifndef ENETUNREACH
#define ENETUNREACH 101
#endif
#ifndef ENETRESET
#define ENETRESET 102
#endif
#ifndef ECONNABORTED
#define ECONNABORTED 103
#endif
#ifndef ECONNRESET
#define ECONNRESET 104
#endif
#ifndef ENOBUFS
#define ENOBUFS 105
#endif
#ifndef EISCONN
#define EISCONN 106
#endif
#ifndef ENOTCONN
#define ENOTCONN 107
#endif
#ifndef ESHUTDOWN
#define ESHUTDOWN 108
#endif
#ifndef ETOOMANYREFS
#define ETOOMANYREFS 109
#endif
#ifndef ETIMEDOUT
#define ETIMEDOUT 110
#endif
#ifndef ECONNREFUSED
#define ECONNREFUSED 111
#endif
#ifndef EHOSTDOWN
#define EHOSTDOWN 112
#endif
#ifndef EHOSTUNREACH
#define EHOSTUNREACH 113
#endif
#ifndef EALREADY
#define EALREADY 114
#endif
#ifndef EINPROGRESS
#define EINPROGRESS 115
#endif
#ifndef ESTALE
#define ESTALE 116
#endif
#ifndef EDQUOT
#define EDQUOT 122
#endif

#ifndef EINVAL
#define EINVAL 22
#endif
#ifndef ENFILE
#define ENFILE 23
#endif
#ifndef EMFILE
#define EMFILE 24
#endif
#ifndef ENOTTY
#define ENOTTY 25
#endif
#ifndef ETXTBSY
#define ETXTBSY 26
#endif
#ifndef EFBIG
#define EFBIG 27
#endif
#ifndef ENOSPC
#define ENOSPC 28
#endif
#ifndef ESPIPE
#define ESPIPE 29
#endif
#ifndef EROFS
#define EROFS 30
#endif
#ifndef EMLINK
#define EMLINK 31
#endif
#ifndef EPIPE
#define EPIPE 32
#endif
#ifndef EDOM
#define EDOM 33
#endif
#ifndef ERANGE
#define ERANGE 34
#endif
#ifndef EDEADLK
#define EDEADLK 35
#endif
#ifndef ENAMETOOLONG
#define ENAMETOOLONG 36
#endif
#ifndef ENOLCK
#define ENOLCK 37
#endif
#ifndef ENOSYS
#define ENOSYS 38
#endif
#ifndef ENOTEMPTY
#define ENOTEMPTY 39
#endif
#ifndef ELOOP
#define ELOOP 40
#endif

#ifndef ENOENT
#define ENOENT 2
#endif
#ifndef ESRCH
#define ESRCH 3
#endif
#ifndef EINTR
#define EINTR 4
#endif
#ifndef EIO
#define EIO 5
#endif
#ifndef ENXIO
#define ENXIO 6
#endif
#ifndef E2BIG
#define E2BIG 7
#endif
#ifndef ENOEXEC
#define ENOEXEC 8
#endif
#ifndef EBADF
#define EBADF 9
#endif
#ifndef ECHILD
#define ECHILD 10
#endif
#ifndef EAGAIN
#define EAGAIN 11
#endif
#ifndef ENOMEM
#define ENOMEM 12
#endif
#ifndef EACCES
#define EACCES 13
#endif
#ifndef EFAULT
#define EFAULT 14
#endif
#ifndef ENOTBLK
#define ENOTBLK 15
#endif
#ifndef EBUSY
#define EBUSY 16
#endif
#ifndef EEXIST
#define EEXIST 17
#endif
#ifndef EXDEV
#define EXDEV 18
#endif
#ifndef ENODEV
#define ENODEV 19
#endif
#ifndef ENOTDIR
#define ENOTDIR 20
#endif
#ifndef EISDIR
#define EISDIR 21
#endif

#define ERRCASE(e) case e: return #e

int err_map(int err) {
#define ERRCASE(err) \
        case err: return _##err;
    switch (err) {
        ERRCASE(EPERM)
        ERRCASE(ENOENT)
        ERRCASE(ESRCH)
        ERRCASE(EINTR)
        ERRCASE(EIO)
        ERRCASE(ENXIO)
        ERRCASE(E2BIG)
        ERRCASE(ENOEXEC)
        ERRCASE(EBADF)
        ERRCASE(ECHILD)
        ERRCASE(EAGAIN)
        ERRCASE(ENOMEM)
        ERRCASE(EACCES)
        ERRCASE(EFAULT)
        ERRCASE(ENOTBLK)
        ERRCASE(EBUSY)
        ERRCASE(EEXIST)
        ERRCASE(EXDEV)
        ERRCASE(ENODEV)
        ERRCASE(ENOTDIR)
        ERRCASE(EISDIR)
        ERRCASE(EINVAL)
        ERRCASE(ENFILE)
        ERRCASE(EMFILE)
        ERRCASE(ENOTTY)
        ERRCASE(ETXTBSY)
        ERRCASE(EFBIG)
        ERRCASE(ENOSPC)
        ERRCASE(ESPIPE)
        ERRCASE(EROFS)
        ERRCASE(EMLINK)
        ERRCASE(EPIPE)
        ERRCASE(EDOM)
        ERRCASE(ERANGE)
        ERRCASE(EDEADLK)
        ERRCASE(ENAMETOOLONG)
        ERRCASE(ENOLCK)
        ERRCASE(ENOSYS)
        ERRCASE(ENOTEMPTY)
        ERRCASE(ELOOP)
        ERRCASE(ENOSTR)
        ERRCASE(ENODATA)
        ERRCASE(ETIME)
        ERRCASE(ENOSR)
        ERRCASE(EREMOTE)
        ERRCASE(ENOLINK)
        ERRCASE(EPROTO)
        ERRCASE(EMULTIHOP)
        ERRCASE(EBADMSG)
        ERRCASE(EOVERFLOW)
        ERRCASE(EILSEQ)
        ERRCASE(EUSERS)
        ERRCASE(ENOTSOCK)
        ERRCASE(EDESTADDRREQ)
        ERRCASE(EMSGSIZE)
        ERRCASE(EPROTOTYPE)
        ERRCASE(ENOPROTOOPT)
        ERRCASE(EPROTONOSUPPORT)
        ERRCASE(ESOCKTNOSUPPORT)
        ERRCASE(EOPNOTSUPP)
#if EOPNOTSUPP != ENOTSUP
        ERRCASE(ENOTSUP)
#endif
        ERRCASE(EPFNOSUPPORT)
        ERRCASE(EAFNOSUPPORT)
        ERRCASE(EADDRINUSE)
        ERRCASE(EADDRNOTAVAIL)
        ERRCASE(ENETDOWN)
        ERRCASE(ENETUNREACH)
        ERRCASE(ENETRESET)
        ERRCASE(ECONNABORTED)
        ERRCASE(ECONNRESET)
        ERRCASE(ENOBUFS)
        ERRCASE(EISCONN)
        ERRCASE(ENOTCONN)
        ERRCASE(ESHUTDOWN)
        ERRCASE(ETOOMANYREFS)
        ERRCASE(ETIMEDOUT)
        ERRCASE(ECONNREFUSED)
        ERRCASE(EHOSTDOWN)
        ERRCASE(EHOSTUNREACH)
        ERRCASE(EALREADY)
        ERRCASE(EINPROGRESS)
        ERRCASE(ESTALE)
        ERRCASE(EDQUOT)
    }
#undef ERRCASE
    printk("unknown error %d\n", err);
    return -(err | 0x1000);
}

int errno_map() {
    if (errno == EPIPE)
        send_signal(current, SIGPIPE_, SIGINFO_NIL);
    return err_map(errno);
}

