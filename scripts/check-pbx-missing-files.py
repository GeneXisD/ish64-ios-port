#!/usr/bin/env python3
from pathlib import Path
import re
import sys

PROJECTS = [
    ("deps/libarchive.xcodeproj/project.pbxproj", "deps/libarchive/libarchive"),
]

pattern = re.compile(r'path = ([^;]+);')

bad = 0

for pbx_path, root in PROJECTS:
    pbx = Path(pbx_path)
    base = Path(root)
    if not pbx.exists():
        print(f"[skip] missing project file: {pbx}")
        continue

    text = pbx.read_text(errors="ignore")
    for line in text.splitlines():
        if ".c" not in line and ".m" not in line and ".mm" not in line:
            continue
        m = pattern.search(line)
        if not m:
            continue
        rel = m.group(1).strip().strip('"')
        if "/" in rel:
            candidate = Path(rel)
        else:
            candidate = base / rel
        if not candidate.exists():
            print(f"[missing] {pbx}: {candidate}")
            bad += 1

if bad:
    sys.exit(1)

print("[ok] no missing source file references found")
