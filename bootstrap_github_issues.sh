#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not installed."
  echo "Install it with Homebrew:"
  echo "  brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated."
  echo "Run:"
  echo "  gh auth login"
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi

if [[ -z "$REPO" ]]; then
  echo "Could not determine the repo automatically."
  echo "Run the script like this:"
  echo "  ./bootstrap_github_issues.sh GeneXisD/ish64-ios-port"
  exit 1
fi

echo "Using repo: $REPO"

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  if gh label list --repo "$REPO" --limit 200 | awk '{print $1}' | grep -Fxq "$name"; then
    echo "Label exists: $name"
  else
    gh label create "$name" \
      --repo "$REPO" \
      --color "$color" \
      --description "$description"
    echo "Created label: $name"
  fi
}

create_issue_if_missing() {
  local title="$1"
  local body="$2"
  local labels="$3"

  if gh issue list --repo "$REPO" --state all --search "$title in:title" --json title -q '.[].title' | grep -Fxq "$title"; then
    echo "Issue exists: $title"
  else
    gh issue create \
      --repo "$REPO" \
      --title "$title" \
      --body "$body" \
      --label "$labels"
    echo "Created issue: $title"
  fi
}

echo
echo "Creating labels..."
create_label "build" "1d76db" "Build system, compile, and toolchain work"
create_label "dependencies" "5319e7" "Dependency and submodule work"
create_label "documentation" "0e8a16" "Documentation improvements"
create_label "runtime" "fbca04" "Runtime and execution milestone work"
create_label "triage" "d4c5f9" "Needs review and sorting"
create_label "good first issue" "7057ff" "Good entry point for contributors"
create_label "help wanted" "008672" "Maintainer is explicitly looking for help"
create_label "enhancement" "a2eeef" "Improvement or new capability"
create_label "bug" "d73a4a" "Something is broken"

echo
echo "Creating issues..."

create_issue_if_missing \
"Build: verify Xcode compile status" \
"## Goal

Validate the current Xcode build process and document any failures or required environment setup.

## Tasks

- Confirm current Xcode version and SDK requirements
- Attempt a clean build from the current repository state
- Record exact errors, warnings, and blockers
- Add notes to the README or a follow-up issue

## Deliverable

A reproducible summary of the current build state, including logs and environment details." \
"build,triage,help wanted"

create_issue_if_missing \
"Deps: audit libapps dependency" \
"## Goal

Investigate the dependency structure in \`deps/libapps\` and determine the best integration strategy.

## Questions

- Is this intended to remain a submodule, vendored source tree, or pinned dependency?
- What exact revision should be considered canonical?
- Are there local modifications that should be preserved?

## Deliverable

A short recommendation for how \`deps/libapps\` should be managed going forward." \
"dependencies,triage,help wanted"

create_issue_if_missing \
"Deps: audit libarchive dependency" \
"## Goal

Review how \`libarchive\` is integrated and what version or revision is required.

## Questions

- How is it wired into the build?
- Is the current revision intentional?
- Should it remain a separate dependency, a submodule, or vendored code?

## Deliverable

A dependency management recommendation and any cleanup steps needed." \
"dependencies,triage,help wanted"

create_issue_if_missing \
"Docs: contributor quickstart" \
"## Goal

Create a minimal contributor onboarding path so new developers can start quickly.

## Include

- prerequisites
- clone instructions
- branch workflow
- build steps
- known issues

## Deliverable

A concise quickstart section or standalone onboarding document." \
"documentation,good first issue,help wanted"

create_issue_if_missing \
"Runtime: define minimal success milestone" \
"## Goal

Define the smallest reproducible runtime milestone for the ish64 iOS port.

## Candidate targets

- project builds cleanly
- app launches
- hello world execution
- syscall validation milestone

## Deliverable

A clear milestone definition with acceptance criteria." \
"runtime,triage,help wanted"

echo
echo "Done."
echo
echo "Suggested next commands:"
echo "  gh issue list --repo $REPO"
echo "  gh label list --repo $REPO"
