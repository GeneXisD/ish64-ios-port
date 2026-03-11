#!/usr/bin/env bash
set -euo pipefail
OUT="/tmp/errno-uses-$(date +%s).txt"
echo "Searching for errno + common error constants..."
if command -v rg >/dev/null 2>&1; then
  rg --line-number --hidden --glob '!node_modules' "errno|EINPROGRESS|ECONNREFUSED|EHOSTUNREACH" . > "$OUT" || true
else
  grep -R --line-number -E "errno|EINPROGRESS|ECONNREFUSED|EHOSTUNREACH" . > "$OUT" || true
fi
echo "Results written to: $OUT"
wc -l "$OUT"

