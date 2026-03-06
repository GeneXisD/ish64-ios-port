#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }; }
need_cmd python3

# Insert includes after the initial comment block (/* ... */ or // ...),
# otherwise before first #include, otherwise at top.
python3 - "$ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])

PATCHES = {
    root / "kernel" / "init.c": ["signal.h"],

    root / "emu" / "tinyemu" / "slirp" / "tcp_input.c": ["errno.h", "string.h"],
    root / "emu" / "tinyemu" / "slirp" / "socket.c": ["errno.h", "string.h"],
}

include_re = re.compile(r'^\s*#\s*include\s*[<"]([^>"]+)[>"]\s*$', re.M)

def find_insertion_index(lines):
    """
    Return index in 'lines' where we should insert includes.
    Strategy:
      - Skip leading blank lines
      - If file starts with /* ... */ comment, insert after it (and trailing blanks)
      - Else if starts with // comment block, insert after consecutive // lines
      - Else insert before first #include
      - Else insert at top
    """
    n = len(lines)
    i = 0

    # skip leading blank lines
    while i < n and lines[i].strip() == "":
        i += 1

    if i < n and lines[i].lstrip().startswith("/*"):
        # consume until closing */
        while i < n:
            if "*/" in lines[i]:
                i += 1
                break
            i += 1
        # skip blank lines after header
        while i < n and lines[i].strip() == "":
            i += 1
        return i

    if i < n and lines[i].lstrip().startswith("//"):
        while i < n and lines[i].lstrip().startswith("//"):
            i += 1
        while i < n and lines[i].strip() == "":
            i += 1
        return i

    # otherwise, before first include
    for j, line in enumerate(lines):
        if line.lstrip().startswith("#include"):
            return j

    return 0

def patch_file(path: Path, headers):
    if not path.exists():
        print(f"skip: {path} (not found)")
        return

    text = path.read_text(encoding="utf-8", errors="replace")
    existing = set(include_re.findall(text))

    to_add = [h for h in headers if h not in existing]
    if not to_add:
        print(f"ok:   {path} (no changes)")
        return

    lines = text.splitlines(True)
    idx = find_insertion_index(lines)

    block = "".join([f"#include <{h}>\n" for h in to_add]) + "\n"

    # backup
    bak = path.with_suffix(path.suffix + ".bak")
    bak.write_text(text, encoding="utf-8")

    # insert
    lines.insert(idx, block)
    new_text = "".join(lines)
    path.write_text(new_text, encoding="utf-8")

    print(f"patch: {path} (+ {', '.join(to_add)})  backup: {bak.name}")

for p, hdrs in PATCHES.items():
    patch_file(p, hdrs)

print("done.")
PY
