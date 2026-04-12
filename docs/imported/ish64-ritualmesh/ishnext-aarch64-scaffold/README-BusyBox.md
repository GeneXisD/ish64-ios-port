# BusyBox Dual Integration Add‑On (for iSH‑NEXT, Intel Mac friendly)

This add‑on gives you two paths:

1) **ELF BusyBox (static, AArch64)** for validating your loader on macOS (mapping only).
2) **libbusybox (Mach‑O, arm64)** to link into an iOS app so you can run a shell on device without executing external ELF.

## Files

- `scripts/fetch_busybox_static.sh` — Robust fetch/extract of AArch64 static BusyBox into `assets/busybox-static-aarch64`.
- `scripts/build_busybox_ios.sh` — Builds `libbusybox.a` for arm64 iOS using Xcode toolchain and stages headers/libs under `third_party/busybox/`.
- `user/busybox_tramp.c` — Trampoline to call `busybox_main("sh")` from your iOS app.
- `README-BusyBox.md` — These instructions.

## Quick Usage

```bash
# From your scaffold root after unzipping these files into it:
bash scripts/fetch_busybox_static.sh
bash scripts/build_busybox_ios.sh

# Verify artifacts:
file assets/busybox-static-aarch64
ls -l third_party/busybox/lib/libbusybox.a
```

Then add `user/busybox_tramp.c` to your Xcode target and call `ishnext_shell()`.
