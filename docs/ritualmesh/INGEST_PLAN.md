# Ish64-Ritualmesh Ingest Plan

This document maps the separate `GeneXisD/Ish64-Ritualmesh` bootstrap repository into the main `GeneXisD/ish64-ios-port` tree.

## Source repository contents observed

The current `Ish64-Ritualmesh` repository contains these top-level items:

- `ishnext-aarch64-scaffold/`
- `ishnext-addon/`
- `ishnext-firstboot-patch/`
- `.gitmodules`
- `alpine-minirootfs-3.22.2-aarch64.tar`
- `busybox-static-1.37.0-r24.apk`
- `.DS_Store` (should not be migrated)

## Recommended destination inside `ish64-ios-port`

| Source | Destination | Reason |
|---|---|---|
| `ishnext-aarch64-scaffold/` | `docs/imported/ish64-ritualmesh/ishnext-aarch64-scaffold/` | Preserve experimental scaffold without colliding with upstream core paths. |
| `ishnext-addon/` | `docs/imported/ish64-ritualmesh/ishnext-addon/` | Keep addon work grouped with the imported bootstrap set. |
| `ishnext-firstboot-patch/` | `patches/ritualmesh/ishnext-firstboot-patch/` | Patch material belongs with other patch assets. |
| `alpine-minirootfs-3.22.2-aarch64.tar` | `runtime/experimental/inputs/` | Runtime input artifact, not root-level source. |
| `busybox-static-1.37.0-r24.apk` | `runtime/experimental/inputs/` | Runtime input artifact, not root-level source. |
| `.gitmodules` | review manually before merge | Only migrate submodule definitions that are still needed. |
| `.DS_Store` | do not migrate | macOS metadata only. |

## Merge rules

1. Do not overwrite existing upstream iSH core files blindly.
2. Keep imported work under clearly named integration paths until each file is reviewed.
3. Treat tarballs, APKs, and other large bootstrap artifacts as inputs, not source code.
4. Remove `.DS_Store` from the source repository history going forward.
5. After import, decide whether the imported scaffold should stay in-tree or be replaced by a reproducible fetch/build script.

## Immediate next step

Run `scripts/import_ish64_ritualmesh.sh` from the repository root to pull the separate repository into the mapped locations above.
