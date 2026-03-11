#!/bin/bash
# Fix 64-bit to 32-bit casts in TinyEMU sources

# cutils.h
sed -i '' 's/\*(uint32_t *)ptr = v;/\*(uint32_t *)ptr = (uint32_t)v;/' emu/tinyemu/cutils.h
sed -i '' 's/put_be32(d + 4, v);/put_be32(d + 4, (uint32_t)v);/' emu/tinyemu/cutils.h

# tcp_input.c
sed -i '' 's/tp->snd_wnd = tiwin;/tp->snd_wnd = (uint32_t)tiwin;/' emu/tinyemu/slirp/tcp_input.c

# fs/stat.c
sed -i '' 's/newstat.fucked_ino = stat.inode;/newstat.fucked_ino = (dword_t)stat.inode;/' fs/stat.c
sed -i '' 's/statx.rdev_major = dev_major(stat.rdev);/statx.rdev_major = (dev_t_)dev_major(stat.rdev);/' fs/stat.c
sed -i '' 's/statx.rdev_minor = dev_minor(stat.rdev);/statx.rdev_minor = (dev_t_)dev_minor(stat.rdev);/' fs/stat.c
sed -i '' 's/statx.dev_major = dev_major(stat.dev);/statx.dev_major = (dev_t_)dev_major(stat.dev);/' fs/stat.c
sed -i '' 's/statx.dev_minor = dev_minor(stat.dev);/statx.dev_minor = (dev_t_)dev_minor(stat.dev);/' fs/stat.c

echo "All uint32 casts applied successfully."

