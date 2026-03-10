# Error Tracking

This document lists known build issues and how to fix them.

---

## libarchive project corrupted

Error example:

"The project 'libarchive' is damaged and cannot be opened due to a parse error."

Fix:

Run the repair script:

```
python scripts/patch-libarchive-pbx.py
```

---

## Missing Meson / Ninja

Install with Homebrew:

```
brew install meson ninja
```

---

## Python version mismatch

Recommended Python:

```
Python 3.12
```

---

## Build artifacts interfering with build

Clean build cache:

```
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

---

## Reporting new errors

Open a GitHub issue and include:

* build log
* macOS version
* Xcode version
* hardware architecture

