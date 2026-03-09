#!/usr/bin/env bash
set -e

ROOT=$(pwd)

echo "Initializing guest OS profiles..."

mkdir -p rootfs_profiles
mkdir -p rootfs_profiles/ish-alpine-x86
mkdir -p rootfs_profiles/linux64-aarch64-test
mkdir -p rootfs_profiles/slackware64

############################################
# iSH Alpine profile (existing environment)
############################################

cat > rootfs_profiles/ish-alpine-x86/manifest.json <<EOF
{
  "name": "iSH Alpine",
  "arch": "x86",
  "abi": "linux",
  "backend": "ish-x86",
  "init": "/bin/sh"
}
EOF

############################################
# Linux64 ARM64 test profile
############################################

cat > rootfs_profiles/linux64-aarch64-test/manifest.json <<EOF
{
  "name": "Linux64 ARM Test",
  "arch": "aarch64",
  "abi": "linux",
  "backend": "linux64-aarch64",
  "init": "/bin/sh"
}
EOF

mkdir -p rootfs_profiles/linux64-aarch64-test/bin

############################################
# Download static BusyBox for ARM64
############################################

echo "Downloading BusyBox aarch64..."

curl -L \
https://busybox.net/downloads/binaries/1.36.0-defconfig-multiarch/busybox-aarch64 \
-o rootfs_profiles/linux64-aarch64-test/bin/busybox

chmod +x rootfs_profiles/linux64-aarch64-test/bin/busybox

ln -sf busybox rootfs_profiles/linux64-aarch64-test/bin/sh

############################################
# Slackware64 placeholder profile
############################################

cat > rootfs_profiles/slackware64/manifest.json <<EOF
{
  "name": "Slackware64",
  "arch": "x86_64",
  "abi": "linux",
  "backend": "linux64-x86_64",
  "init": "/bin/bash"
}
EOF

############################################
# OS selector configuration
############################################

cat > rootfs_profiles/default_profile <<EOF
ish-alpine-x86
EOF

############################################
# Create profile loader helper
############################################

mkdir -p scripts

cat > scripts/select_rootfs_profile.sh <<'EOF'
#!/usr/bin/env bash

PROFILE_FILE="rootfs_profiles/default_profile"

if [ ! -f "$PROFILE_FILE" ]; then
  echo "No default profile set"
  exit 1
fi

PROFILE=$(cat "$PROFILE_FILE")

echo "Using OS profile: $PROFILE"

ROOTFS_DIR="rootfs_profiles/$PROFILE"

if [ ! -d "$ROOTFS_DIR" ]; then
  echo "Profile directory missing"
  exit 1
fi

echo "$ROOTFS_DIR"
EOF

chmod +x scripts/select_rootfs_profile.sh

############################################
# Display results
############################################

echo ""
echo "Guest OS profiles installed:"
echo ""

ls rootfs_profiles

echo ""
echo "Default OS:"
cat rootfs_profiles/default_profile

echo ""
echo "You can switch OS by editing:"
echo "rootfs_profiles/default_profile"
