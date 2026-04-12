#ifndef FIBER_FRAME_H
#define FIBER_FRAME_H
#include <stddef.h>
#include <stdint.h>
struct fiber_frame { void *bp; void *ret_cache; void *value; void *value_addr; void *last_block; };
#endif
