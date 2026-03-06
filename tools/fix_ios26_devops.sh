#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/Projects/ish64}"
cd "$ROOT"

echo "[*] Working in: $ROOT"

need_file() {
  [[ -f "$1" ]] || { echo "[!] Missing file: $1" >&2; exit 1; }
}

need_file "fs/dev.h"
need_file "fs/tty.c"

timestamp="$(date +%Y%m%d-%H%M%S)"
cp -av fs/dev.h "fs/dev.h.bak.${timestamp}"
cp -av fs/tty.c "fs/tty.c.bak.${timestamp}"

python3 <<'PY'
from pathlib import Path
import re
import sys

dev_h = Path("fs/dev.h")
tty_c = Path("fs/tty.c")

orig = dev_h.read_text()

# ------------------------------------------------------------------
# Step 1: keep exactly one struct dev_ops, preferring the fuller one.
# ------------------------------------------------------------------
matches = list(re.finditer(r'\bstruct\s+dev_ops\s*\{', orig))
if not matches:
    print("[!] No struct dev_ops found in fs/dev.h", file=sys.stderr)
    sys.exit(1)

def find_block_end(text, start_idx):
    brace = text.find("{", start_idx)
    if brace < 0:
        return -1
    depth = 0
    for i in range(brace, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                semi = text.find(";", i)
                return semi + 1 if semi != -1 else i + 1
    return -1

blocks = []
for m in matches:
    s = m.start()
    e = find_block_end(orig, s)
    if e == -1:
        print("[!] Could not parse struct dev_ops block", file=sys.stderr)
        sys.exit(1)
    block = orig[s:e]
    blocks.append((s, e, block))

# Prefer the block that has the most expected members.
score_terms = [
    ".fd", "struct fd_ops", "getpath", "readlink", "stat", "open",
    "struct mount", "struct path", "const char *name"
]
def score(block):
    return sum(1 for t in score_terms if t in block)

best_idx = max(range(len(blocks)), key=lambda i: score(blocks[i][2]))
best_block = blocks[best_idx][2]

text = orig

# Remove all struct dev_ops definitions
for s, e, _ in reversed(blocks):
    text = text[:s] + text[e:]

# ------------------------------------------------------------------
# Step 2: remove problematic include cycles from fs/dev.h.
# ------------------------------------------------------------------
# We do NOT want fs/fd.h pulled in before dev_t_ is declared.
text = re.sub(r'^[ \t]*#include\s+"fs/fd\.h"\s*\n', '', text, flags=re.M)

# Also avoid pulling kernel/fs.h too early if it was added here.
# Keep project-local includes minimal in this header.
text = re.sub(r'^[ \t]*#include\s+"kernel/fs\.h"\s*\n', '', text, flags=re.M)

# ------------------------------------------------------------------
# Step 3: ensure system includes exist.
# ------------------------------------------------------------------
if '#include <sys/types.h>' not in text:
    text = text.replace('#ifndef FS_DEV_H\n#define FS_DEV_H\n',
                        '#ifndef FS_DEV_H\n#define FS_DEV_H\n\n#include <sys/types.h>\n')
if '#include <stdint.h>' not in text:
    text = text.replace('#include <sys/types.h>\n',
                        '#include <sys/types.h>\n#include <stdint.h>\n')

# ------------------------------------------------------------------
# Step 4: ensure dev_t_ typedef/helpers exist before any project types.
# ------------------------------------------------------------------
dev_helpers = r'''typedef unsigned int dev_t_;

static inline dev_t_ dev_make(dev_t_ major_, dev_t_ minor_) {
    return ((major_ & 0xffffu) << 16) | (minor_ & 0xffffu);
}

static inline dev_t_ dev_major(dev_t_ dev) {
    return (dev >> 16) & 0xffffu;
}

static inline dev_t_ dev_minor(dev_t_ dev) {
    return dev & 0xffffu;
}

static inline dev_t real_dev(dev_t_ dev) {
    return (dev_t) dev;
}

static inline dev_t_ fake_dev(dev_t dev) {
    return (dev_t_) dev;
}

static inline dev_t dev_real_from_fake(dev_t_ dev) {
    return real_dev(dev);
}

static inline dev_t_ dev_fake_from_real(dev_t dev) {
    return fake_dev(dev);
}
'''
if 'typedef unsigned int dev_t_;' not in text:
    marker = '#include <stdint.h>\n'
    if marker in text:
        text = text.replace(marker, marker + '\n' + dev_helpers + '\n')
    else:
        text = text.replace('#define FS_DEV_H\n', '#define FS_DEV_H\n\n' + dev_helpers + '\n')

# ------------------------------------------------------------------
# Step 5: ensure BSD typedef shims exist once.
# ------------------------------------------------------------------
bsd_shims = r'''
#ifndef __U_INT_DEFINED_ISH64
#define __U_INT_DEFINED_ISH64
typedef unsigned int u_int;
#endif

#ifndef __U_CHAR_DEFINED_ISH64
#define __U_CHAR_DEFINED_ISH64
typedef unsigned char u_char;
#endif

#ifndef __U_SHORT_DEFINED_ISH64
#define __U_SHORT_DEFINED_ISH64
typedef unsigned short u_short;
#endif
'''.strip()

if '__U_INT_DEFINED_ISH64' not in text:
    insert_after = 'static inline dev_t_ dev_fake_from_real(dev_t dev) {\n    return fake_dev(dev);\n}\n'
    if insert_after in text:
        text = text.replace(insert_after, insert_after + '\n\n' + bsd_shims + '\n')
    else:
        text += '\n\n' + bsd_shims + '\n'

# ------------------------------------------------------------------
# Step 6: forward declarations so dev_ops can mention these types
# without dragging in include cycles.
# ------------------------------------------------------------------
fwd = r'''
struct fd;
struct fd_ops;
struct mount;
struct path;
struct statbuf;
'''.strip()

if 'struct fd;' not in text:
    # place after shims if present
    anchor = '#endif\n\n#ifndef __U_CHAR_DEFINED_ISH64'
    # easier: append after u_short block
    u_short_block = '#endif\n'
    pos = text.rfind(u_short_block)
    if pos != -1:
        text = text[:pos+len(u_short_block)] + '\n' + fwd + '\n' + text[pos+len(u_short_block):]
    else:
        text += '\n' + fwd + '\n'

# ------------------------------------------------------------------
# Step 7: normalize the kept struct dev_ops block so open has the
# 3-argument signature expected by tty_device_open.
# ------------------------------------------------------------------
block = best_block

# Replace any existing open callback line inside the struct.
block = re.sub(
    r'int\s*\(\s*\*\s*open\s*\)\s*\([^;]*\)\s*;',
    'int (*open)(int major, int minor, struct fd *fd);',
    block
)

# If no open line found, add one near the top.
if '(*open)' not in block:
    block = block.replace('{', '{\n    int (*open)(int major, int minor, struct fd *fd);', 1)

# Make sure struct fd_ops fd; exists if the original fuller struct had it or tty/mem initializers need it.
if 'struct fd_ops fd;' not in block and '.fd.' in Path("fs/tty.c").read_text() + Path("fs/mem.c").read_text():
    # insert before final closing brace
    block = re.sub(r'\}\s*;?\s*$', '    struct fd_ops fd;\n};', block.strip(), flags=re.S)

# Ensure commonly used members exist if missing.
if 'const char *name;' not in block and '.name =' in (
    Path("fs/pty.c").read_text() +
    Path("fs/mem.c").read_text() +
    Path("fs/dyndev.c").read_text()
):
    block = block.replace('{', '{\n    const char *name;', 1)

if '(*getpath)' not in block and '.getpath =' in (
    Path("fs/fake.c").read_text() +
    Path("fs/real.c").read_text() +
    Path("fs/tmp.c").read_text()
):
    block = block.replace('struct fd_ops fd;', 'int (*getpath)(struct mount *mount, struct path *path, char *buf);\n    struct fd_ops fd;')

if '(*readlink)' not in block and '.readlink =' in (
    Path("fs/fake.c").read_text() +
    Path("fs/real.c").read_text() +
    Path("fs/proc.c").read_text()
):
    block = block.replace('struct fd_ops fd;', 'int (*readlink)(struct mount *mount, struct path *path, char *buf);\n    struct fd_ops fd;')

if '(*stat)' not in block and '.stat =' in (
    Path("fs/fake.c").read_text() +
    Path("fs/real.c").read_text() +
    Path("fs/tmp.c").read_text()
):
    block = block.replace('struct fd_ops fd;', 'int (*stat)(struct mount *mount, struct path *path, struct statbuf *stat);\n    struct fd_ops fd;')

# ------------------------------------------------------------------
# Step 8: insert the final dev_ops block once, before the closing endif.
# ------------------------------------------------------------------
insert_point = text.rfind('#endif')
if insert_point == -1:
    print("[!] Could not find closing #endif in fs/dev.h", file=sys.stderr)
    sys.exit(1)

text = text[:insert_point].rstrip() + '\n\n' + block.strip() + '\n\n' + text[insert_point:]

# Collapse accidental triple blank lines.
text = re.sub(r'\n{3,}', '\n\n', text)

dev_h.write_text(text)

# ------------------------------------------------------------------
# Step 9: fix tty open initializer mismatch with a wrapper, only if needed.
# ------------------------------------------------------------------
tty = tty_c.read_text()

if 'static int tty_dev_open_wrapper(' not in tty:
    m = re.search(r'\bint\s+tty_device_open\s*\(\s*int\s+\w+\s*,\s*int\s+\w+\s*,\s*struct fd \*\w+\s*\)', tty)
    if m:
        # insert wrapper before struct dev_ops tty_dev
        wrapper = r'''
static int tty_dev_open_wrapper(int major, int minor, struct fd *fd) {
    return tty_device_open(major, minor, fd);
}
'''.strip() + '\n\n'
        tty = re.sub(r'(\bstruct\s+dev_ops\s+tty_dev\s*=\s*\{)', wrapper + r'\1', tty, count=1)

tty = tty.replace('.open = tty_device_open,', '.open = tty_dev_open_wrapper,')

tty_c.write_text(tty)

print("[*] fs/dev.h and fs/tty.c patched.")
PY

echo
echo "[*] Verification"
awk '/struct dev_ops[[:space:]]*\{/{print "  struct dev_ops at line " NR}' fs/dev.h || true
echo "  dev_t_ typedef count: $(grep -c 'typedef unsigned int dev_t_;' fs/dev.h || true)"
echo "  fs/fd.h include count in fs/dev.h: $(grep -c '#include \"fs/fd.h\"' fs/dev.h || true)"
echo "  tty wrapper present: $(grep -c 'tty_dev_open_wrapper' fs/tty.c || true)"

echo
echo "[*] First 140 lines of fs/dev.h"
sed -n '1,140p' fs/dev.h

echo
echo "[*] Rebuilding ishcore"
cd ios/build-xcode
xcodebuild -scheme ish64_ios -configuration Debug -destination 'generic/platform=iOS' -target ishcore 2>&1 | tee /tmp/ish64-build.log || true

echo
echo "[*] Top build errors"
grep -nE "error:|fatal error:" /tmp/ish64-build.log | head -30 || true
