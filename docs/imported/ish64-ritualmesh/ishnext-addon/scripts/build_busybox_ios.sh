#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Ensure Xcode toolchain exists
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
CLANG=$(xcrun --sdk iphoneos -f clang)

# Clone BusyBox if needed
if [[ ! -d third_party/src/busybox ]]; then
  mkdir -p third_party/src
  echo "[+] Cloning BusyBox (official git)"
  if ! git clone https://git.busybox.net/busybox third_party/src/busybox; then
    echo "[!] Official git failed; trying GitHub mirror"
    git clone https://github.com/mirror/busybox.git third_party/src/busybox
  fi
fi

pushd third_party/src/busybox >/dev/null

# Configure
echo "[+] Configuring BusyBox for lib build (arm64 iOS)"
make distclean || true
make defconfig

# Toggle options
# Enable libbusybox
perl -0777 -pe 's/# CONFIG_FEATURE_LIBBUSYBOX is not set/CONFIG_FEATURE_LIBBUSYBOX=y/' -i .config
# Ensure dynamic (not static) for library
perl -0777 -pe 's/CONFIG_STATIC=y/# CONFIG_STATIC is not set/' -i .config
# Prefer ash as /bin/sh
perl -0777 -pe 's/# CONFIG_SH_IS_ASH is not set/CONFIG_SH_IS_ASH=y/' -i .config
perl -0777 -pe 's/CONFIG_SH_IS_NONE=y/# CONFIG_SH_IS_NONE is not set/' -i .config

make oldconfig </dev/null

# Build libbusybox for arm64 iOS
echo "[+] Building libbusybox.a (arm64 iOS)"
make -j$(sysctl -n hw.ncpu) \
  CC="$CLANG -arch arm64 -isysroot $SDK --target=arm64-apple-ios12.0 -fembed-bitcode -fvisibility=hidden" \
  AR="$(xcrun --sdk iphoneos -f ar)" \
  RANLIB="$(xcrun --sdk iphoneos -f ranlib)" \
  libbusybox

popd >/dev/null

# Stage outputs
mkdir -p third_party/busybox/lib third_party/busybox/include
cp third_party/src/busybox/libbusybox.a third_party/busybox/lib/
rsync -a --delete --exclude='.git' third_party/src/busybox/include/ third_party/busybox/include/ || true

echo "[+] Staged:"
ls -l third_party/busybox/lib/libbusybox.a
