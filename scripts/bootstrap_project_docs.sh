#!/usr/bin/env bash
set -e

echo "Rebuilding project documentation..."

mkdir -p .github/ISSUE_TEMPLATE

########################################
# README
########################################

cat > README.md << 'EOF'
# ish64 iOS Port

Experimental work toward a 64-bit architecture build of the iSH Linux userspace emulator for iOS.

## Current Status

- Repository stabilized
- Clean main branch
- Rescue snapshot preserved
- Feature branches enabled

Current focus:

• reproducible build  
• dependency cleanup  
• runtime milestone  
• contributor onboarding  

## Project Goal

Develop and experiment with a 64-bit architecture path for iSH while remaining compatible with upstream.

Upstream:
https://github.com/ish-app/ish

## Repo Structure

deps/ – external dependencies  
ios/ – iOS integration  
iSH.xcodeproj – Xcode project  

## Branch Model

main → stable baseline  
feature/* → development  
rescue/* → recovery snapshots  
experiment/* → prototypes  

## Getting Started

Clone:

git clone git@github.com:GeneXisD/ish64-ios-port.git  
cd ish64-ios-port  

Create a branch:

git checkout -b feature/my-work

Push:

git push --set-upstream origin feature/my-work

## Help Wanted

Build validation  
Dependency cleanup  
Runtime milestone definition  
Documentation
EOF


########################################
# CONTRIBUTING
########################################

cat > CONTRIBUTING.md << 'EOF'
# Contributing

## Workflow

1 Clone repo  
2 Create feature branch  
3 Implement changes  
4 Submit PR  

Example:

git checkout -b feature/my-improvement

## Branch Naming

feature/<topic>  
fix/<bug>  
docs/<documentation>  
experiment/<prototype>  

## Pull Requests

Include:

• change description  
• build status  
• reproduction steps  
• logs if relevant
EOF


########################################
# ROADMAP
########################################

cat > ROADMAP.md << 'EOF'
# Roadmap

Phase 1 – Repository stabilization  
Phase 2 – Reproducible builds  
Phase 3 – Runtime milestone  
Phase 4 – Architecture experimentation  
Phase 5 – Integration and polish
EOF


########################################
# STATUS
########################################

cat > STATUS.md << 'EOF'
# Project Status

Repository stabilized

Main branch restored  
Rescue snapshot preserved  
Development on feature branches

Focus areas:

build validation  
dependency cleanup  
runtime milestone
EOF


########################################
# ABOUT
########################################

cat > ABOUT.md << 'EOF'
Experimental 64-bit architecture port and development environment for the iSH Linux emulator on iOS.
EOF


########################################
# ISSUE TEMPLATES
########################################

cat > .github/ISSUE_TEMPLATE/build.md << 'EOF'
---
name: Build validation
about: Verify build process
title: "Build validation"
labels: build
---

Validate Xcode build status and document failures.
EOF


cat > .github/ISSUE_TEMPLATE/deps.md << 'EOF'
---
name: Dependency audit
about: Review dependencies
title: "Dependency audit"
labels: dependencies
---

Audit deps directory and verify dependency structure.
EOF


cat > .github/ISSUE_TEMPLATE/runtime.md << 'EOF'
---
name: Runtime milestone
about: Define minimal runtime target
title: "Runtime milestone"
labels: runtime
---

Define minimal successful execution milestone.
EOF


########################################
# PR TEMPLATE
########################################

cat > .github/pull_request_template.md << 'EOF'
## Summary

Describe the change.

## Type

Build  
Runtime  
Docs  
Refactor  

## Validation

Built locally  
Tested locally
EOF


########################################
# Gitignore fix
########################################

grep -qxF '.DS_Store' .gitignore 2>/dev/null || echo '.DS_Store' >> .gitignore


echo
echo "Documentation rebuilt successfully."
echo
echo "Next commands:"
echo "git add README.md CONTRIBUTING.md ROADMAP.md STATUS.md ABOUT.md .github .gitignore"
echo "git commit -m \"Project documentation and contributor setup\""
echo "git push"
