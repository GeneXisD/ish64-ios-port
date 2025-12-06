# Replace include lines in the slirp sources we modified earlier:
FILES=(
  emu/tinyemu/slirp/socket.c
  emu/tinyemu/slirp/slirp.c
  emu/tinyemu/slirp/ip_icmp.c
  emu/tinyemu/slirp/tcp_input.c
  emu/tinyemu/slirp/bootp.c
  emu/tinyemu/slirp/ip_input.c
  emu/tinyemu/slirp/mbuf.c
  emu/tinyemu/slirp/mbuf.c  # appears twice in logs; harmless
)

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    # if it already includes the relative path, skip
    if grep -q '#include "../../compat/ios_fixes.h"' "$f"; then
      echo "OK: $f already uses relative include"
    else
      # replace "compat/ios_fixes.h" with ../../compat/ios_fixes.h
      perl -0777 -pe 's/#include\s+"compat\/ios_fixes.h"/#include "..\/..\/compat\/ios_fixes.h"/g' -i "$f"
      echo "Patched include in $f"
    fi
  else
    echo "Missing file: $f (skipped)"
  fi
done

