#pragma once

/* Apple Clang compatibility layer for TinyEMU / SLIRP */

#if defined(__APPLE__) && defined(__clang__)

/* ISH_FALLTHROUGH handling — safe */
#if __has_attribute(ISH_FALLTHROUGH)
#  define FALLTHROUGH __attribute__((ISH_FALLTHROUGH))
#else
#  define FALLTHROUGH
#endif

/* unreachable */
#ifndef unreachable
#  define unreachable() __builtin_unreachable()
#endif

/* force inline */
#ifndef force_inline
#  define force_inline __attribute__((always_inline)) inline
#endif

/* noinline */
#ifndef noinline
#  define noinline __attribute__((noinline))
#endif

#endif /* __APPLE__ && __clang__ */

