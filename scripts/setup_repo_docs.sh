#!/usr/bin/env bash
set -e

echo "[ish64] Creating documentation structure..."

mkdir -p docs .github/ISSUE_TEMPLATE

# README
printf '%s\n' \
'[![Build](https://github.com/GeneXisD/ish64-ios-port/actions/workflows/build.yml/badge.svg)](https://github.com/GeneXisD/ish64-ios-port/actions)' \
'' \
'English | [한국어](README_KO.md) | [日本語](README_JP.md) | [中文](README_ZH.md)' \
'' \
'# ish64' \
'' \
'Experimental fork of the iSH emulator focused on build reproducibility and contributor onboarding.' \
'' \
'## Quick start' \
'' \
'```bash' \
'./scripts/dev-build.sh' \
'```' \
'' \
'## Documentation' \
'- BUILDING.md' \
'- CONTRIBUTING.md' \
'- CHANGELOG.md' \
'- CREDITS.md' \
'- ERROR_TRACKING.md' \
'- ROADMAP.md' \
> README.md

# BUILDING
printf '%s\n' \
'# Building ish64' \
'' \
'Requirements:' \
'- macOS' \
'- Xcode' \
'- Meson' \
'- Ninja' \
'' \
'Build:' \
'```bash' \
'./scripts/dev-build.sh' \
'```' \
> BUILDING.md

# CONTRIBUTING
printf '%s\n' \
'# Contributing' \
'' \
'1. Run the build:' \
'```bash' \
'./scripts/dev-build.sh' \
'```' \
'' \
'2. If the build fails:' \
'```bash' \
'./scripts/dev-clean.sh' \
'```' \
> CONTRIBUTING.md

# CHANGELOG
printf '%s\n' \
'# Changelog' \
'' \
'## Unreleased' \
'- build stabilization' \
'- dependency fixes' \
> CHANGELOG.md

# CREDITS
printf '%s\n' \
'# Credits' \
'' \
'Project Steward: Victor Jose Corral' \
'' \
'Based on:' \
'https://github.com/ish-app/ish' \
> CREDITS.md

# ROADMAP
printf '%s\n' \
'# Roadmap' \
'' \
'Near term:' \
'- stabilize build system' \
'- improve contributor workflow' \
'' \
'Long term:' \
'- architecture experimentation for ish64' \
> ROADMAP.md

# ERROR TRACKING
printf '%s\n' \
'# Error Tracking' \
'' \
'Common fixes:' \
'' \
'Clean Xcode cache:' \
'```bash' \
'rm -rf ~/Library/Developer/Xcode/DerivedData/*' \
'```' \
> ERROR_TRACKING.md

echo "[ish64] Documentation generated successfully."
