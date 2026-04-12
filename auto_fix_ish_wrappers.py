#!/usr/bin/env python3
"""
auto_fix_ish_wrappers.py
Generates 6-arg syscall wrappers for ish64 to eliminate cast warnings.
"""

import re
from pathlib import Path

# Paths
KERNEL_DIR = Path("./kernel")
OUTPUT_FILE = KERNEL_DIR / "syscall_wrappers.c"

# Match function signatures like: int_t sys_eventfd(fd_t a, int_t b)
FUNC_RE = re.compile(r'^(?:int|int_t|dword_t|uint_t)\s+(sys_\w+)\s*\(([^)]*)\)')

# Convert argument list to count
def count_args(arg_list):
    if not arg_list.strip() or arg_list.strip() == "void":
        return 0
    return len(arg_list.split(','))

wrappers = []

# Scan all .c files in kernel/
for cfile in KERNEL_DIR.glob("*.c"):
    with cfile.open() as f:
        for line in f:
            line = line.strip()
            m = FUNC_RE.match(line)
            if m:
                name = m.group(1)
                args = m.group(2)
                nargs = count_args(args)
                wrapper = f"""
// Wrapper for {name}
static int {name}_wrapper(unsigned int a, unsigned int b, unsigned int c,
                          unsigned int d, unsigned int e, unsigned int f) {{
    return {name}({', '.join(['a','b','c','d','e','f'][:nargs])});
}}
"""
                wrappers.append(wrapper)

# Write the output file
with OUTPUT_FILE.open("w") as f:
    f.write("// Auto-generated syscall wrappers\n")
    f.write('#include "calls.h"\n\n')
    f.write("\n".join(wrappers))

print(f"[+] Generated {len(wrappers)} wrappers in {OUTPUT_FILE}")
