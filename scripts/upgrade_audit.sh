#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
TARGET_VERSION="${1:-15.0}"

say() { printf "\n==> %s\n" "$*"; }
note() { printf "  - %s\n" "$*"; }
warn() { printf "  ! %s\n" "$*"; }
ok() { printf "  ✓ %s\n" "$*"; }

require_repo_root() {
  if [[ ! -d .git ]] && [[ ! -f .git ]]; then
    echo "Run this from the repository root."
    exit 1
  fi
}

ensure_paths() {
  say "Ensuring structure folders exist"
  mkdir -p patches docs/archive scripts .github/workflows
  ok "Created/verified: patches docs/archive scripts .github/workflows"
}

audit_docs() {
  say "Checking contributor-facing docs"
  local files=(
    README.md
    BUILDING.md
    CONTRIBUTING.md
    CHANGELOG.md
    CREDITS.md
    ERROR_TRACKING.md
    PROJECT_STATUS.md
    ROADMAP.md
  )
  local missing=0
  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      ok "$f"
    else
      warn "Missing: $f"
      missing=1
    fi
  done
  return 0
}

audit_scripts() {
  say "Checking core helper scripts"
  local files=(
    scripts/dev-build.sh
    scripts/dev-clean.sh
    scripts/dev-bootstrap.sh
    scripts/bootstrap-deps.sh
    scripts/check-pbx-missing-files.py
    scripts/patch-libarchive-pbx.py
  )
  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      ok "$f"
    else
      warn "Missing: $f"
    fi
  done
}

list_workflows() {
  say "Workflow inventory"
  if compgen -G ".github/workflows/*.yml" > /dev/null; then
    ls -1 .github/workflows
  else
    warn "No workflow files found"
  fi

  if [[ -f .github/workflows/ci.yml ]]; then
    ok "Primary CI workflow present: ci.yml"
  else
    warn "Primary CI workflow missing: ci.yml"
  fi

  if [[ -f .github/workflows/build.yml ]]; then
    warn "Duplicate-style workflow still present: build.yml"
  fi
}

audit_readme_badge() {
  say "Checking README CI badge"
  if [[ -f README.md ]]; then
    if grep -q "actions/workflows/ci.yml/badge.svg" README.md; then
      ok "README points to ci.yml badge"
    else
      warn "README does not point to ci.yml badge"
    fi
  else
    warn "README.md missing"
  fi
}

deployment_files() {
  find iSH.xcodeproj deps -type f \( -name "project.pbxproj" -o -name "*.xcconfig" \) 2>/dev/null
}

show_deployment_targets() {
  say "Current deployment target audit"
  local found=0
  while IFS= read -r f; do
    if grep -q "IPHONEOS_DEPLOYMENT_TARGET = " "$f" 2>/dev/null; then
      found=1
      echo "--- $f"
      grep "IPHONEOS_DEPLOYMENT_TARGET = " "$f" | sort -u
    fi
  done < <(deployment_files)

  if [[ "$found" -eq 0 ]]; then
    warn "No deployment target entries found"
  fi
}

normalize_deployment_targets() {
  say "Normalizing deployment targets to iOS $TARGET_VERSION"
  local changed=0
  while IFS= read -r f; do
    if grep -q "IPHONEOS_DEPLOYMENT_TARGET = " "$f" 2>/dev/null; then
      cp "$f" "$f.bak_upgrade_audit"
      python3 - "$f" "$TARGET_VERSION" <<'PY'
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
target = sys.argv[2]
text = path.read_text()
new = re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;', f'IPHONEOS_DEPLOYMENT_TARGET = {target};', text)
path.write_text(new)
PY
      changed=1
      ok "Updated $f"
    fi
  done < <(deployment_files)

  if [[ "$changed" -eq 0 ]]; then
    warn "Nothing updated"
  fi
}

check_capability_hint() {
  say "Capability reminder"
  note "In Xcode, verify Signing & Capabilities does not include unused Background Modes such as Location updates."
}

audit_git_state() {
  say "Git remotes"
  git remote -v || true

  say "Git status"
  git status --short || true
}

audit_branch_and_worktree() {
  say "Branch summary"
  git branch --show-current || true

  local ahead_behind
  ahead_behind="$(git status --short --branch 2>/dev/null | /usr/bin/head -n 1 || true)"
  [[ -n "$ahead_behind" ]] && note "$ahead_behind"
}

check_duplicate_status_docs() {
  say "Checking overlapping status/error files"
  local dupes=(
    ERRORS.md
    STATUS.md
  )
  for f in "${dupes[@]}"; do
    if [[ -f "$f" ]]; then
      warn "Potential duplicate/overlap present: $f"
    fi
  done
}

summary() {
  say "Where you are at"
  note "Repo structure checked"
  note "Docs inventory checked"
  note "Workflow inventory checked"
  note "README badge checked"
  note "Deployment targets audited${NORMALIZED:+ and normalized}"
  note "Git remotes and working tree reviewed"
  echo
  echo "Suggested next commands:"
  echo "  git diff"
  echo "  git status"
  echo "  ./scripts/dev-bootstrap.sh    # if present"
  echo "  ./scripts/dev-build.sh        # if present"
}

main() {
  require_repo_root
  ensure_paths
  audit_docs
  audit_scripts
  list_workflows
  audit_readme_badge
  show_deployment_targets

  if [[ "${APPLY_FIXES:-0}" == "1" ]]; then
    normalize_deployment_targets
    NORMALIZED=1
    show_deployment_targets
  fi

  check_duplicate_status_docs
  check_capability_hint
  audit_branch_and_worktree
  audit_git_state
  summary
}

NORMALIZED=""
main "$@"
