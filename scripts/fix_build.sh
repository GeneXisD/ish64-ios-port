#!/bin/bash

echo "Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/iSH*

echo "Cleaning build directories..."
rm -rf build

echo "Updating git submodules..."
git submodule update --init --recursive

echo "Fixing deployment targets..."
find . -name project.pbxproj -exec sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 11.0/IPHONEOS_DEPLOYMENT_TARGET = 13.0/g' {} \;

echo "Done. Reopen Xcode and build again."
