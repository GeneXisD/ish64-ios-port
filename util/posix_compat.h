#pragma once

/* This file normalizes POSIX behavior across
 * macOS / iOS / Linux for iSH kernel + slirp
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>
#include <time.h>

/* ---------- errno normalization ---------- */

#ifndef EINPROGRESS
#define EINPROGRESS 36
#endif

#ifndef EWOULDBLOCK
#define EWOULDBLOCK EAGAIN
#endif

#ifndef ECONNREFUSED
#define ECONNREFUSED 61
#endif

#ifndef EHOSTUNREACH
#define EHOSTUNREACH 65
#endif

#ifndef ENETUNREACH
#define ENETUNREACH 51
#endif

/* Explicit strerror declaration (Clang strict mode) */
#ifdef __cplusplus
extern "C" {
#endif
char *strerror(int);
#ifdef __cplusplus
}
#endif

/* ---------- stat time normalization ---------- */

#if defined(__APPLE__) || defined(__MACH__)
    #define STAT_ATIME_SEC(st)   ((st)->st_atimespec.tv_sec)
    #define STAT_MTIME_SEC(st)   ((st)->st_mtimespec.tv_sec)
    #define STAT_ATIME_NSEC(st)  ((st)->st_atimespec.tv_nsec)
    #define STAT_MTIME_NSEC(st)  ((st)->st_mtimespec.tv_nsec)
#else
    #define STAT_ATIME_SEC(st)   ((st)->st_atim.tv_sec)
    #define STAT_MTIME_SEC(st)   ((st)->st_mtim.tv_sec)
    #define STAT_ATIME_NSEC(st)  ((st)->st_atim.tv_nsec)
    #define STAT_MTIME_NSEC(st)  ((st)->st_mtim.tv_nsec)
#endif

