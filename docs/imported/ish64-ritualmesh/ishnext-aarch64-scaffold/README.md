# iSH-NEXT (AArch64) — Full Scaffold (M0–M2)

This repository is a **starter kit** for building an AArch64 Linux userspace on iOS using a WSL1-style syscall shim. It focuses on the early milestones:

- **M0**: Static ELF loader + core syscalls (read/write/openat/close/fstat/lseek/mmap/mprotect/brk/exit)
- **M1**: Dynamic loader path (PT_INTERP) with musl `ld-musl-aarch64.so.1` and auxv
- **M2**: Threads + futex basic ops

It is **not** an iOS app yet. You'll drop this into an Xcode project as a static library or source group later. For now you can build a host tool on macOS to exercise the ELF loader and syscall shims with dummy backends.

## Layout

```
ishnext/
  loader/
  kernel/
  include/
  user/
  tests/
  assets/
  scripts/
  Makefile        # macOS host build for early bring-up
```

## Quick Start (Host Build on macOS)

> This builds a **host dev binary** so you can iterate on the ELF loader, not an iOS app.

```bash
# 1) Build
make

# 2) Run a smoke test (prints fake /proc and exits)
./bin/ishnext-dev --selftest

# 3) (Later) Provide a static busybox (aarch64) and try to 'exec' it
#    by mapping it and jumping to its entry point (still stubbed here).
```

## Integrating with Xcode (later)

- Create a new Xcode iOS app (SwiftUI or UIKit).
- Add `loader/`, `kernel/`, `include/`, `user/` sources into a static library target.
- Link the static lib into your app, call `ishnext_boot()` from `user/init.c` on app startup.
- Replace host `mach_compat_*` stubs with their iOS equivalents.
- Honor iOS sandbox rules: no writable+executable pages; avoid JIT; do not map external code as executable.

## Rootfs & BusyBox (placeholders)

- Put an **AArch64 Alpine minirootfs tar** into `assets/alpine-aarch64-minirootfs.tar` (not included here).
- Put a **static busybox (AArch64)** into `assets/busybox-static-aarch64` (not included).
- Use `scripts/pack_rootfs.sh` to stage the rootfs into `Documents/rootfs` layout (for iOS) or `./rootfs` for host testing.

## Milestone Guidance

- **M0**: Implement syscall table entries in `kernel/sys_table.c` and the handlers in `kernel/*.c`. The default returns `-ENOSYS`.
- **M1**: Implement dynamic loader in `loader/elf64.c` to map `ld-musl-aarch64.so.1`, set up auxv (`AT_*`), and jump to the dynamic loader.
- **M2**: Add pthread-backed clone/futex in `kernel/clone.c` and `kernel/futex.c`.

## Legal

This scaffold is original boilerplate for educational/research purposes. You are responsible for complying with Apple platform policies and third-party licenses for any rootfs or binaries you package.

