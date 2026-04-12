#pragma once
static inline long linux_err(int posix_errno) {
    switch (posix_errno) {
        case 1:  return -1;  // EPERM
        case 2:  return -2;  // ENOENT
        case 9:  return -9;  // EBADF
        case 12: return -12; // ENOMEM
        case 13: return -13; // EACCES
        case 14: return -14; // EFAULT
        case 22: return -22; // EINVAL
        case 38: return -38; // ENOSYS (not really returned by POSIX, here for mapping completeness)
        default: return -22; // EINVAL fallback
    }
}
