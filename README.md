[![Build](https://github.com/GeneXisD/ish64-ios-port/actions/workflows/build.yml/badge.svg)](https://github.com/GeneXisD/ish64-ios-port/actions)

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
