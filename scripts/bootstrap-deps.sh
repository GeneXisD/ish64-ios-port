#!/usr/bin/env bash
set -euo pipefail

echo "[ish64] Syncing submodules..."
git submodule sync --recursive
git submodule update --init --recursive

echo "[ish64] Resetting vendor deps to pinned commits..."
git -C deps/libarchive reset --hard
git -C deps/libarchive clean -fdx
git -C deps/libapps reset --hard
git -C deps/libapps clean -fdx

echo "[ish64] Done."
