#!/usr/bin/env bash
set -euo pipefail

# Files to search for patterns - adapt as needed
PATTERN="errno|EINPROGRESS|ECONNREFUSED|EHOSTUNREACH|wrlock_init|write_wrlock|write_wrunlock|wrlock_destroy"
TMP="/tmp/patch_includes_$(date +%s)"
mkdir -p "$TMP"

echo "Finding candidate source files..."
if command -v rg >/dev/null 2>&1; then
  rg --files-with-matches --hidden --glob '!node_modules' -e "$PATTERN" . > "$TMP/files.txt" || true
else
  grep -R --files-with-matches -E "$PATTERN" . > "$TMP/files.txt" || true
fi

echo "Files identified: $(wc -l < "$TMP/files.txt")"
echo

# function to insert includes after top cluster of #include lines
insert_includes() {
  local file="$1"
  local backup="${file}.bak_patch"
  cp "$file" "$backup"

  # decide which includes to add
  local add_errno=0 add_string=0 add_wrlock=0

  grep -q -E '\berrno\b|EINPROGRESS|ECONNREFUSED|EHOSTUNREACH' "$file" && add_errno=1
  grep -q -E '\bstrerror\(|\bE[A-Z]+' "$file" || true  # noop
  grep -q -F 'string.h' "$file" && add_string=0 || true

  # If file references strerror or uses errno messages, also add string.h
  if grep -q 'strerror(' "$file" 2>/dev/null; then
    add_string=1
  fi

  if grep -q -E 'wrlock_init|write_wrlock|write_wrunlock|wrlock_destroy' "$file" 2>/dev/null; then
    add_wrlock=1
  fi

  # If file already contains the include, don't add
  if grep -q '#include <errno.h>' "$file"; then add_errno=0; fi
  if grep -q '#include <string.h>' "$file"; then add_string=0; fi
  if grep -q '#include "util/wrlock_compat.h"' "$file" -s; then add_wrlock=0; fi

  # If nothing to add, exit
  if [ $add_errno -eq 0 ] && [ $add_string -eq 0 ] && [ $add_wrlock -eq 0 ]; then
    return 0
  fi

  # Build insert text
  insert=""
  [ $add_errno -eq 1 ] && insert="${insert}#include <errno.h>\n"
  [ $add_string -eq 1 ] && insert="${insert}#include <string.h>\n"
  [ $add_wrlock -eq 1 ] && insert="${insert}#include \"util/wrlock_compat.h\"\n"

  # Insert after top block of includes (heuristic)
  awk -v insert="$insert" '
  BEGIN{printed=0}
  {
    if(!printed){
      # detect end of contiguous include block
      if ($0 ~ /^#\s*include/){
        includes[++n] = $0
        next
      } else if(n>0){
        # print collected includes, then insert new ones, then print current line
        for(i=1;i<=n;i++) print includes[i]
        printf "%s", insert
        printed=1
        print $0
        next
      } else {
        print $0
      }
    } else {
      print $0
    }
  }
  END{
    if(!printed && n>0){
      for(i=1;i<=n;i++) print includes[i]
      printf "%s", insert
    }
  }' "$backup" > "$file"
  echo "Patched: $file (backup at $backup)"
}

# iterate files
while IFS= read -r f; do
  # skip binary files
  if file "$f" | grep -q text; then
    insert_includes "$f"
  else
    echo "Skipping non-text: $f"
  fi
done < "$TMP/files.txt"

echo "Done. Inspect changes and run a build."

