#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/victorj/Projects/ish64"

backup() {
  local f="$1"
  [[ -f "$f" && ! -f "$f.bak" ]] && cp "$f" "$f.bak"
}

FILES=(
  "$ROOT/emu/tinyemu/slirp/socket.c"
  "$ROOT/fs/sock.c"
  "$ROOT/fs/poll.c"
  "$ROOT/fs/real.c"
  "$ROOT/fs/dev.h"
  "$ROOT/fs/sock.h"
)

for f in "${FILES[@]}"; do
  backup "$f"
done

python3 <<'PY'
from pathlib import Path
import re

ROOT = Path("/Users/victorj/Projects/ish64")

def ensure_after_first_include_block(text, inserts):
    lines = text.splitlines()
    out = []
    inserted = False
    i = 0
    while i < len(lines):
        out.append(lines[i])
        i += 1
        if not inserted and i < len(lines) and not lines[i].startswith("#include"):
            for ins in inserts:
                if ins not in text:
                    out.append(ins)
            inserted = True
            out.extend(lines[i:])
            return "\n".join(out) + "\n"
    if not inserted:
        for ins in inserts:
            if ins not in text:
                out.append(ins)
    return "\n".join(out) + "\n"

def add_unique_include_after(text, marker, include_line):
    if include_line in text:
        return text
    if marker in text:
        return text.replace(marker, marker + include_line + "\n", 1)
    return include_line + "\n" + text

# 1) slirp/socket.c
socket_c = ROOT / "emu/tinyemu/slirp/socket.c"
text = socket_c.read_text()

for bad in [
    '#include "../../../util/errno_compat.h"\n',
    '#include <errno.h>\n',
    '#include <sys/errno.h>\n',
    '#include <string.h>\n',
]:
    text = text.replace(bad, "")

text = add_unique_include_after(text, '#include "slirp.h"\n', '#include <sys/socket.h>')
text = add_unique_include_after(text, '#include <sys/socket.h>\n', '#include <errno.h>')
text = add_unique_include_after(text, '#include <errno.h>\n', '#include <string.h>')
socket_c.write_text(text)

# 2) fs/sock.c
sock_c = ROOT / "fs/sock.c"
text = sock_c.read_text()
for inc in ['#include <errno.h>', '#include <sys/errno.h>']:
    if inc not in text:
        text = ensure_after_first_include_block(text, [inc])
sock_c.write_text(text)

# 3) fs/poll.c
poll_c = ROOT / "fs/poll.c"
text = poll_c.read_text()
needed = ['#include <errno.h>']
for inc in needed:
    if inc not in text:
        text = ensure_after_first_include_block(text, [inc])
poll_c.write_text(text)

# 4) fs/real.c
real_c = ROOT / "fs/real.c"
text = real_c.read_text()

needed = [
    '#include <sys/types.h>',
    '#include <sys/socket.h>',
    '#include <sys/stat.h>',
    '#include <sys/sysmacros.h>',
    '#include <netinet/in.h>',
    '#include <netinet/ip.h>',
    '#include <netinet/ip6.h>',
    '#include <arpa/inet.h>',
]
for inc in needed:
    if inc not in text:
        text = ensure_after_first_include_block(text, [inc])

# Darwin stat fields fallback
text = text.replace('real_stat->st_atimespec.tv_sec', 'real_stat->st_atim.tv_sec')
text = text.replace('real_stat->st_mtimespec.tv_sec', 'real_stat->st_mtim.tv_sec')
text = text.replace('real_stat->st_ctimespec.tv_sec', 'real_stat->st_ctim.tv_sec')
text = text.replace('real_stat->st_atimespec.tv_nsec', 'real_stat->st_atim.tv_nsec')
text = text.replace('real_stat->st_mtimespec.tv_nsec', 'real_stat->st_mtim.tv_nsec')
text = text.replace('real_stat->st_ctimespec.tv_nsec', 'real_stat->st_ctim.tv_nsec')

real_c.write_text(text)

# 5) fs/dev.h
dev_h = ROOT / "fs/dev.h"
text = dev_h.read_text()
needed = [
    '#include <sys/types.h>',
    '#include <sys/sysmacros.h>',
]
for inc in needed:
    if inc not in text:
        text = ensure_after_first_include_block(text, [inc])
dev_h.write_text(text)

# 6) fs/sock.h
sock_h = ROOT / "fs/sock.h"
text = sock_h.read_text()

needed = [
    '#include <sys/types.h>',
    '#include <sys/socket.h>',
    '#include <netinet/in.h>',
    '#include <netinet/ip.h>',
    '#include <netinet/ip6.h>',
]
for inc in needed:
    if inc not in text:
        text = ensure_after_first_include_block(text, [inc])

compat_block = r'''
#ifndef AF_LOCAL
#define AF_LOCAL AF_UNIX
#endif

#ifndef PF_LOCAL
#define PF_LOCAL PF_UNIX
#endif

#ifndef MSG_DONTWAIT
#define MSG_DONTWAIT 0
#endif

#ifndef SO_TIMESTAMP
#define SO_TIMESTAMP 0x0400
#endif

#ifndef IP_TOS
#define IP_TOS 3
#endif

#ifndef IP_TTL
#define IP_TTL 4
#endif

#ifndef IP_HDRINCL
#define IP_HDRINCL 2
#endif

#ifndef IP_RETOPTS
#define IP_RETOPTS 8
#endif

#ifndef IP_RECVTTL
#define IP_RECVTTL 24
#endif

#ifndef IP_RECVTOS
#define IP_RECVTOS 27
#endif

#ifndef IPV6_TCLASS
#define IPV6_TCLASS 36
#endif

#ifndef IPPROTO_ICMPV6
#define IPPROTO_ICMPV6 58
#endif
'''.strip() + "\n"

if "ifndef AF_LOCAL" not in text:
    text = compat_block + "\n" + text

sock_h.write_text(text)

print("patched compatibility files")
PY

cat > "$ROOT/ios/rebuild_ish64.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

cd /Users/victorj/Projects/ish64/ios

xcodebuild \
  -scheme ish64_ios \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -target ishcore
SH

chmod +x "$ROOT/ios/rebuild_ish64.sh"

echo
echo "Patched files:"
printf ' - %s\n' "${FILES[@]}"
echo
echo "Now run:"
echo "  /Users/victorj/Projects/ish64/ios/rebuild_ish64.sh"
