#!/usr/bin/env bash
set -euo pipefail
# This script stages an Alpine AArch64 minirootfs tar to ./rootfs (host) or to an export dir for iOS.
# Usage: scripts/pack_rootfs.sh path/to/alpine-aarch64-minirootfs.tar
TAR="${1:-}"
if [[ -z "$TAR" || ! -f "$TAR" ]]; then
  echo "Usage: $0 path/to/alpine-aarch64-minirootfs.tar" >&2
  exit 1
fi
mkdir -p rootfs
tar -xf "$TAR" -C rootfs
echo "rootfs staged at ./rootfs"
