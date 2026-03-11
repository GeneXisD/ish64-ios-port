#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-$PWD}"
cd "$REPO_DIR"

echo "[*] Working in: $PWD"

if [ ! -d .git ]; then
  echo "[!] This is not a git repository."
  exit 1
fi

YEAR="$(date +%Y)"
AUTHOR="Victor Jose Corral"
REPO_URL="https://github.com/GeneXisD/ish64-ios-port"

echo "[*] Creating standard directories..."
mkdir -p docs scripts patches

move_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    echo "    moving $src -> $dst"
    git mv "$src" "$dst" 2>/dev/null || mv "$src" "$dst"
  fi
}

echo "[*] Moving documentation files..."
for f in PROJECT_STATUS.md ERROR_TRACKING.md ERRORS.md CONTRIBUTING.md CREDITS.md ABOUT.md CHANGELOG.md BUILDING.md; do
  [ -e "$f" ] && move_if_exists "$f" "docs/$f"
done

echo "[*] Moving common scripts..."
for f in *.sh; do
  [ -e "$f" ] || continue
  case "$f" in
    fix_ish64_compliance.sh) continue ;;
    *)
      move_if_exists "$f" "scripts/$f"
      ;;
  esac
done

echo "[*] Moving patch files..."
for f in *.patch; do
  [ -e "$f" ] || continue
  move_if_exists "$f" "patches/$f"
done

echo "[*] Ensuring LICENSE exists..."
if [ ! -f LICENSE ]; then
  cat > LICENSE <<'EOF'
NOTICE:
This repository appears to be derived from upstream iSH and/or related components.
You must replace this placeholder with the exact upstream license text used by the original project.

Do not leave this placeholder in production.
EOF
  echo "    created placeholder LICENSE (replace with exact upstream license text)"
fi

echo "[*] Writing LICENSE-ISH64..."
cat > LICENSE-ISH64 <<EOF
ish64 modifications
Copyright (c) $YEAR $AUTHOR

This repository is based on upstream open-source software.
All original code retains its original copyright and license terms.

Modifications and additional components introduced in the ish64 project
are released under the same upstream license unless otherwise specified
in individual files or directories.

Project repository:
$REPO_URL
EOF

echo "[*] Writing third-party license inventory..."
cat > docs/THIRD_PARTY_LICENSES.md <<'EOF'
# Third-Party Licenses

This file tracks major third-party components used in this repository.
Review and update it as dependencies change.

## Upstream / Third-Party Components

### iSH
- Purpose: Upstream emulator/runtime base
- License: Verify upstream license and keep exact original text in LICENSE
- Source: https://github.com/ish-app/ish

### Linux kernel components
- Purpose: Kernel-derived headers/code/components if included
- License: GPLv2 (verify exact files used)
- Source: https://www.kernel.org/

### Meson
- Purpose: Build system files if derived from upstream Meson examples or tooling
- License: Verify applicable upstream license
- Source: https://mesonbuild.com/

### Other bundled or copied components
Document each additional component here with:
- name
- purpose
- source URL
- license
- files/directories affected

## Maintainer Notes

1. Keep all upstream copyright notices intact.
2. Do not remove original license files from imported code.
3. If a subdirectory has different license terms, add a local NOTICE or LICENSE file there.
4. If you copied code from another project, record it here immediately.
EOF

echo "[*] Creating NOTICE..."
cat > NOTICE <<EOF
This repository contains original work and modifications by $AUTHOR.

It may also contain code and assets derived from upstream open-source projects.
All upstream copyright and license notices must be preserved.

See:
- LICENSE
- LICENSE-ISH64
- docs/THIRD_PARTY_LICENSES.md
EOF

echo "[*] Ensuring root BUILD_GUIDE.md exists..."
if [ ! -f BUILD_GUIDE.md ]; then
  cat > BUILD_GUIDE.md <<EOF
# Build Guide

**Author:** $AUTHOR

## Overview

This document describes the general build workflow for the iSH64 project and its development environment.

## Requirements

- macOS
- Xcode
- Git
- Apple command line developer tools
- repository access
- optional GitHub Actions runner support

## Local Build Flow

\`\`\`bash
git clone $REPO_URL
cd ish64-ios-port
xcodebuild -project iSH.xcodeproj -scheme iSH -configuration Release
\`\`\`

## Notes

Expand this file with:
- dependency requirements
- signing details
- simulator/device targets
- troubleshooting
- CI/CD workflow notes
EOF
fi

echo "[*] Ensuring root ARCHITECTURE.md exists..."
if [ ! -f ARCHITECTURE.md ]; then
  cat > ARCHITECTURE.md <<EOF
# iSH64 Project Architecture

**Author:** $AUTHOR

## Purpose

iSH64 is an experimental 64-bit Linux environment for iOS derived from the iSH architecture.
It is intended as a platform for runtime portability, userland experimentation, and systems research.

## Core Layers

1. iOS Host Environment
2. iSH64 Runtime Layer
3. Linux Userland Layer
4. Experimental Integration Layer

## Goals

- support 64-bit userland experimentation
- improve developer workflows
- support networking and security research
- keep the architecture modular and maintainable
EOF
fi

echo "[*] Updating README license section if missing..."
if [ -f README.md ]; then
  if ! grep -q "^## License" README.md; then
    cat >> README.md <<'EOF'

## License

This project is based on upstream open-source software and retains all original
license notices where applicable.

Additional modifications for the ish64 project are documented in `LICENSE-ISH64`.

See also:
- `LICENSE`
- `LICENSE-ISH64`
- `NOTICE`
- `docs/THIRD_PARTY_LICENSES.md`
EOF
  fi
else
  cat > README.md <<EOF
# iSH64 – 64-bit Linux Environment for iOS

**Author:** $AUTHOR  
**Repository:** $REPO_URL

## Overview

iSH64 is an experimental 64-bit Linux environment for iOS derived from upstream emulator architecture.

## License

This project is based on upstream open-source software and retains all original
license notices where applicable.

Additional modifications for the ish64 project are documented in \`LICENSE-ISH64\`.

See also:
- \`LICENSE\`
- \`LICENSE-ISH64\`
- \`NOTICE\`
- \`docs/THIRD_PARTY_LICENSES.md\`
EOF
fi

echo "[*] Creating .github pull request / issue docs only if folder exists..."
mkdir -p .github

echo "[*] Final git status:"
git status --short || true

echo "[*] Staging changes..."
git add .

if ! git diff --cached --quiet; then
  git commit -m "Organize repo structure and add compliance documentation" || true
  echo "[*] Commit created."
else
  echo "[*] No staged changes to commit."
fi

echo
echo "[+] Done."
echo "[!] IMPORTANT:"
echo "    1. Replace placeholder LICENSE with the exact upstream license text."
echo "    2. Review docs/THIRD_PARTY_LICENSES.md and fill in every imported component."
echo "    3. Inspect any copied code for per-file copyright headers."
