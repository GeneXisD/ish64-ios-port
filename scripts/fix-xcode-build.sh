#!/usr/bin/env bash
set -euo pipefail

echo "[1/6] Cleaning DerivedData and local build outputs..."
rm -rf ~/Library/Developer/Xcode/DerivedData/iSH*
rm -rf build meson-build out dist

echo "[2/6] Normalizing deployment target to iOS 13.0 in Xcode projects..."
find . \( -name project.pbxproj -o -name "*.xcconfig" \) -print0 | while IFS= read -r -d '' f; do
  perl -0pi -e 's/IPHONEOS_DEPLOYMENT_TARGET = 11\.0;/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/g' "$f" || true
done

echo "[3/6] Ensuring fakefs.c has required headers..."
python3 - <<'PY'
from pathlib import Path
p = Path("tools/fakefs.c")
text = p.read_text()

need = [
    "#include <stdio.h>",
    "#include <unistd.h>",
    "#include <sys/unistd.h>",
]

anchor = "#if ISH_LINUX\n"
if anchor in text:
    start = text.index(anchor) + len(anchor)
    block = text[start:start+500]
    missing = [h for h in need if h not in text]
    if missing:
        insert = "".join(h + "\n" for h in missing)
        text = text.replace(anchor, anchor + insert, 1)
        p.write_text(text)
PY

echo "[4/6] Syncing submodules..."
git submodule sync --recursive
git submodule update --init --recursive

echo "[5/6] Showing remaining deployment targets..."
grep -R "IPHONEOS_DEPLOYMENT_TARGET =" iSH.xcodeproj deps/*.xcodeproj 2>/dev/null || true

echo "[6/6] Rebuilding..."
xcodebuild \
  -project iSH.xcodeproj \
  -scheme iSH \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  clean build 2>&1 | tee build.log || true

echo
echo "Top build errors:"
grep -n "error:" build.log | /usr/bin/head -20 || true
