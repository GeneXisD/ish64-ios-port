#!/usr/bin/env bash
set -euo pipefail

SRC_REPO_URL="${1:-https://github.com/GeneXisD/Ish64-Ritualmesh.git}"
WORKDIR="${TMPDIR:-/tmp}/ish64-ritualmesh-import.$$"

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo "[+] Cloning source repository: $SRC_REPO_URL"
git clone --depth 1 "$SRC_REPO_URL" "$WORKDIR/src"

mkdir -p docs/imported/ish64-ritualmesh
mkdir -p patches/ritualmesh
mkdir -p runtime/experimental/inputs

for d in ishnext-aarch64-scaffold ishnext-addon; do
  if [ -d "$WORKDIR/src/$d" ]; then
    echo "[+] Importing directory: $d"
    rsync -a --delete "$WORKDIR/src/$d/" "docs/imported/ish64-ritualmesh/$d/"
  fi
done

if [ -d "$WORKDIR/src/ishnext-firstboot-patch" ]; then
  echo "[+] Importing firstboot patch"
  rsync -a --delete "$WORKDIR/src/ishnext-firstboot-patch/" "patches/ritualmesh/ishnext-firstboot-patch/"
fi

for f in alpine-minirootfs-3.22.2-aarch64.tar busybox-static-1.37.0-r24.apk; do
  if [ -f "$WORKDIR/src/$f" ]; then
    echo "[+] Copying artifact: $f"
    cp "$WORKDIR/src/$f" "runtime/experimental/inputs/$f"
  fi
done

# remove macOS metadata if present
find docs/imported/ish64-ritualmesh -name ".DS_Store" -delete || true

cat <<EOF

[✓] Import complete.

Next steps:
  git add docs/imported patches/ritualmesh runtime/experimental/inputs
  git commit -m "Import Ish64-Ritualmesh bootstrap artifacts"
  git push

EOF
