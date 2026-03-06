# ish64 – 64-bit iSH Emulator Port

Author: Victor Jose Corral

## Goal

Port the iSH Linux emulator to a full 64-bit architecture using TinyEMU and modern iOS SDK compatibility layers.

## Current Status

The emulator core and filesystem layers compile, but the build currently stops on Darwin compatibility issues.

### Completed Work

* 64-bit emulator architecture
* Device layer (`dev_ops`)
* Filesystem realfs layer
* Darwin compatibility patches
* TinyEMU integration
* slirp networking integration

### Current Blocking Issues

* `struct stat` compatibility differences on iOS SDK
* `poll()` and POLLIN/POLLOUT compatibility
* errno definitions inside slirp networking

## Environment

* macOS
* Xcode iOS SDK
* TinyEMU
* iSH source base

## Looking For Help

Developers experienced with:

* iOS / Darwin POSIX compatibility
* emulator ports (TinyEMU / QEMU)
* low-level C portability

## License

GPL compatible with original iSH license.

## Status

Work in progress — close to successful build.
