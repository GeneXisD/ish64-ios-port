#!/usr/bin/env bash
set -euo pipefail

BRANCH="$(git branch --show-current)"

echo "[*] Remotes:"
git remote -v
echo

echo "[*] Pushing ${BRANCH} to Gitea..."
git push -u origin "${BRANCH}"

echo "[*] Pushing ${BRANCH} to GitHub..."
git push -u github "${BRANCH}"

echo "[+] Both remotes updated."
