#ifndef FIBER_BLOCK_H
#define FIBER_BLOCK_H
#include <stdint.h>
#include <stdbool.h>
#include "list.h"
#define FIBER_BLOCK_INITIAL_CAPACITY 64
struct fiber_block { void *addr; unsigned long *code; void *end_addr; int is_jetsam; unsigned long **jump_ip; unsigned long *old_jump_ip; struct list_head *jumps_from; struct list_head *jumps_from_links; struct list_head chain; struct list_head *page; };
#endif
