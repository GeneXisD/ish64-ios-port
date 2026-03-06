#pragma once

#include <errno.h>

#ifndef ISH_FALLTHROUGH
#if defined(__has_attribute)
#if __has_attribute(ISH_FALLTHROUGH)
#define ISH_FALLTHROUGH __attribute__((ISH_FALLTHROUGH))
#else
#define ISH_FALLTHROUGH
#endif
#else
#define ISH_FALLTHROUGH
#endif
#endif

