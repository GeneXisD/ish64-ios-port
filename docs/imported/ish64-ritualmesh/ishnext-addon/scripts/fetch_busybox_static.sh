#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p assets tmp_busybox
cd tmp_busybox

echo "[+] Downloading AArch64 busybox-static APK"
APK_URL_BASE="https://dl-cdn.alpinelinux.org/alpine/edge/main/aarch64"

# Try 1.37.0 with many revisions (descending-ish), then 1.36.1 as fallback.
CANDIDATES=(
  busybox-static-1.37.0-r24.apk
  busybox-static-1.37.0-r23.apk
  busybox-static-1.37.0-r22.apk
  busybox-static-1.37.0-r10.apk
  busybox-static-1.37.0-r6.apk
  busybox-static-1.37.0-r5.apk
  busybox-static-1.37.0-r4.apk
  busybox-static-1.37.0-r3.apk
  busybox-static-1.37.0-r2.apk
  busybox-static-1.36.1-r6.apk
  busybox-static-1.36.1-r5.apk
  busybox-static-1.36.1-r4.apk
  busybox-static-1.36.1-r3.apk
  busybox-static-1.36.1-r2.apk
)

APK=""
for CAND in "${CANDIDATES[@]}"; do
  echo "    trying $CAND"
  if curl -fSL --retry 3 --retry-delay 1 -o busybox.apk "$APK_URL_BASE/$CAND"; then
    APK="$CAND"
    break
  fi
done

if [[ -z "$APK" ]]; then
  echo "[!] Failed to download any busybox-static APK candidates." >&2
  echo "    Check network or try Docker fallback (see README-BusyBox.md)." >&2
  exit 1
fi

# Quick sanity checks
if head -n1 busybox.apk | grep -qiE '<!DOCTYPE|<html'; then
  echo "[!] Downloaded HTML error page instead of APK (tar) — CDN or URL issue." >&2
  exit 1
fi
if ! command -v bsdtar >/dev/null 2>&1; then
  echo "[!] bsdtar not found. Install with: brew install libarchive" >&2
  exit 1
fi

echo "[+] Extracting APK layers"
bsdtar -xf busybox.apk || { echo "[!] Failed to extract APK (outer tar)."; exit 1; }

# data.tar can be .gz or .xz depending on the repo snapshot
if ! ls data.tar.* >/dev/null 2>&1; then
  echo "[!] data.tar.* not found in APK. Contents were:" >&2
  ls -la >&2
  exit 1
fi

bsdtar -xf data.tar.* || { echo "[!] Failed to extract data payload (data.tar.*)."; exit 1; }

# Find the busybox.static payload no matter where Alpine placed it
BB_PATH="$(find . -type f -name 'busybox.static' | head -n1 || true)"
if [[ -z "$BB_PATH" ]]; then
  echo "[!] Could not find 'busybox.static' inside data payload." >&2
  echo "    Try another revision or use Docker fallback." >&2
  exit 1
fi

# Stage into assets/
cd ..
mkdir -p assets
cp "tmp_busybox/$BB_PATH" assets/busybox-static-aarch64
chmod +x assets/busybox-static-aarch64

# Verify
echo "[+] Placed assets/busybox-static-aarch64"
if ! file assets/busybox-static-aarch64 | grep -qi 'aarch64'; then
  echo "[!] The file does not look like an AArch64 ELF. File(1) says:" >&2
  file assets/busybox-static-aarch64 >&2
  exit 1
fi

# A small size sanity check — static BusyBox is usually ~1–2 MB
SZ=$(wc -c < assets/busybox-static-aarch64 || echo 0)
if [[ "$SZ" -lt 500000 ]]; then
  echo "[!] BusyBox binary seems too small ($SZ bytes). Extraction likely failed." >&2
  exit 1
fi

# Cleanup
rm -rf tmp_busybox
echo "[✓] assets/busybox-static-aarch64 is ready"

