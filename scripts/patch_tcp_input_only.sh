#!/usr/bin/env bash
set -euo pipefail

FILE="/Users/victorj/Projects/ish64/emu/tinyemu/slirp/tcp_input.c"

cp "$FILE" "${FILE}.bak"

python3 <<'PY'
from pathlib import Path

path = Path("/Users/victorj/Projects/ish64/emu/tinyemu/slirp/tcp_input.c")
text = path.read_text()

need_errno = "#include <errno.h>" not in text
need_string = "#include <string.h>" not in text

if not need_errno and not need_string:
    print("tcp_input.c already has needed includes")
    raise SystemExit(0)

lines = text.splitlines(True)

insert_at = None
for i, line in enumerate(lines):
    if '#include "slirp.h"' in line:
        insert_at = i + 1
        break

if insert_at is None:
    for i, line in enumerate(lines):
        if line.lstrip().startswith("#include"):
            insert_at = i
            break

if insert_at is None:
    insert_at = 0

block = ""
if need_errno:
    block += "#include <errno.h>\n"
if need_string:
    block += "#include <string.h>\n"

lines.insert(insert_at, block)
path.write_text("".join(lines))
print("Patched tcp_input.c")
PY
