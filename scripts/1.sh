# Example fixes in socket.c — backup then apply
SC=emu/tinyemu/slirp/socket.c
if [ -f "$SC" ]; then
  cp "$SC" "$SC.bak"
  # cast recvfrom result assigned to m->m_len
  perl -0777 -pe '
    s{m->m_len\s*=\s*recvfrom\(([^;]+?)\);}{"m->m_len = (int) recvfrom($1);"}gs;
    s{ret\s*=\s*sendto\(([^;]+?)\);}{"ret = (int) sendto($1);"}gs;
  ' -i "$SC"
  echo "Added casts in $SC (backup: $SC.bak)"
fi

