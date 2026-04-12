# iSH-NEXT — Auxv + First-Boot Patch (M0.1)

Adds:
- Auxv builder with AT_PAGESZ, AT_PLATFORM, AT_CLKTCK, AT_HWCAP, AT_RANDOM
- Initial stack synthesis (argv, envp, auxv)
- ELF64 loader integration + dry-run control
- entry jump hook (logs on Intel; callable on arm64)

Usage:
  1) Copy files over your scaffold.
  2) Patch Makefile per Makefile.patch (adds loader/entry.c).
  3) make
  4) ./bin/ishnext-dev --dryrun
