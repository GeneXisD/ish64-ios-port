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
