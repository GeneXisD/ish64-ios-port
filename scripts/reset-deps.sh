#!/bin/bash
echo "[ish64] resetting dependencies"

rm -rf deps/libarchive*
git checkout HEAD -- deps

echo "[ish64] dependencies restored"

