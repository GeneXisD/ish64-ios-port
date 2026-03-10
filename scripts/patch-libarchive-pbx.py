#!/usr/bin/env python3
from pathlib import Path
import re

pbx = Path("deps/libarchive.xcodeproj/project.pbxproj")
root = Path("deps/libarchive/libarchive")
text = pbx.read_text()

# Find file references like:
# ABCD1234 /* archive_getdate.c */ = { ... path = archive_getdate.c; ... };
file_ref_re = re.compile(
    r'(\s*([A-F0-9]{24}) /\* ([^*]+\.c) \*/ = \{[^}]*?path = ([^;]+);[^}]*?\};\n)',
    re.DOTALL
)

to_remove_ids = []
for block, obj_id, comment_name, path_name in file_ref_re.findall(text):
    path_name = path_name.strip().strip('"')
    if not (root / path_name).exists():
        to_remove_ids.append((obj_id, block, path_name))

for obj_id, block, path_name in to_remove_ids:
    print(f"Removing stale file ref: {path_name}")
    text = text.replace(block, "")
    text = re.sub(rf'\s*{obj_id} /\* [^*]+ \*/,?\n', '', text)

pbx.write_text(text)
print("Done.")
