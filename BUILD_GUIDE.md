# Build Guide

**Author:** Victor Jose Corral

## Overview

This document describes the general build workflow for the iSH64 project and its development environment.

## Requirements

- macOS
- Xcode
- Git
- command line developer tools
- repository access
- optional GitHub Actions runner support

## Local Build Flow

```bash
git clone https://github.com/GeneXisD/ish64-ios-port.git
cd ish64-ios-port
xcodebuild -project iSH.xcodeproj -scheme iSH -configuration Release
