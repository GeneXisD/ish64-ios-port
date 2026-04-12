// syscall_wrappers.c
// Auto-generated wrappers for iSH64 syscalls
// Each wrapper matches syscall_t signature (6 unsigned int arguments)

#include "kernel.h"
// syscall_wrappers.c
#include "kernel.h"

// Example wrapper: adapt all syscalls to 6-arg syscall_t signature
int sys_read_wrapper(unsigned int a1, unsigned int a2, unsigned int a3,
                     unsigned int a4, unsigned int a5, unsigned int a6) {
    return sys_read((int)a1, (addr_t)a2, (dword_t)a3);
}

int sys_write_wrapper(unsigned int a1, unsigned int a2, unsigned int a3,
                      unsigned int a4, unsigned int a5, unsigned int a6) {
    return sys_write((int)a1, (addr_t)a2, (dword_t)a3);
}

// Repeat similar wrappers for all syscalls you use
int syscall_stub_wrapper(unsigned int a1, unsigned int a2, unsigned int a3,
                         unsigned int a4, unsigned int a5, unsigned int a6) {
    return -ENOSYS; // syscall not implemented
}
// Example: declare all syscalls
extern dword_t sys_fchmodat(fd_t, addr_t, mode_t_, dword_t);
extern dword_t sys_faccessat(fd_t, addr_t, dword_t, dword_t);
extern dword_t sys_ppoll(addr_t, dword_t, addr_t, addr_t, dword_t);
extern int_t sys_set_robust_list(addr_t, dword_t);
extern int_t sys_get_robust_list(pid_t_, addr_t, addr_t);
extern dword_t sys_utimensat(fd_t, addr_t, addr_t, dword_t);
extern fd_t sys_timerfd_create(int_t, int_t);
extern int_t sys_eventfd(uint_t);
extern int_t sys_timerfd_settime(fd_t, int_t, addr_t, addr_t);
extern int_t sys_eventfd2(uint_t, int_t);
extern fd_t sys_epoll_create(int_t);
extern dword_t sys_dup3(fd_t, fd_t, int_t);
extern int_t sys_pipe2(addr_t, int_t);
extern dword_t syscall_stub(void);
extern dword_t syscall_silent_stub(void);
extern dword_t sys_prlimit64(pid_t_, dword_t, addr_t, addr_t);
extern int_t sys_sendmmsg(fd_t, addr_t, uint_t, int_t);
extern dword_t sys_renameat2(fd_t, addr_t, fd_t, addr_t, int_t);
extern dword_t sys_getrandom(addr_t, dword_t, dword_t);
extern int_t sys_socket(dword_t, dword_t, dword_t);
extern int_t sys_socketpair(dword_t, dword_t, dword_t, addr_t);
extern int_t sys_bind(fd_t, addr_t, uint_t);
extern int_t sys_connect(fd_t, addr_t, uint_t);
extern int_t sys_listen(fd_t, int_t);
extern int_t sys_getsockopt(fd_t, dword_t, dword_t, addr_t, dword_t);
extern int_t sys_setsockopt(fd_t, dword_t, dword_t, addr_t, dword_t);
extern int_t sys_getsockname(fd_t, addr_t, addr_t);
extern int_t sys_getpeername(fd_t, addr_t, addr_t);
extern int_t sys_sendmsg(fd_t, addr_t, int_t);
extern int_t sys_recvmsg(fd_t, addr_t, int_t);
extern int_t sys_shutdown(fd_t, dword_t);
extern dword_t sys_statx(fd_t, addr_t, int_t, uint_t, addr_t);
extern int_t sys_arch_prctl(int_t, addr_t);

// Wrapper macro generator
#define WRAP6(name, ...) \
static int name##_wrapper(unsigned int a, unsigned int b, unsigned int c, \
                         unsigned int d, unsigned int e, unsigned int f) { \
    return name(__VA_ARGS__); \
}

// Generate all wrappers (only passing required arguments)
WRAP6(sys_fchmodat, a, b, c, d)
WRAP6(sys_faccessat, a, b, c, d)
WRAP6(sys_ppoll, a, b, c, d, e)
WRAP6(sys_set_robust_list, a, b)
WRAP6(sys_get_robust_list, a, b, c)
WRAP6(sys_utimensat, a, b, c, d)
WRAP6(sys_timerfd_create, a, b)
WRAP6(sys_eventfd, a)
WRAP6(sys_timerfd_settime, a, b, c, d)
WRAP6(sys_eventfd2, a, b)
WRAP6(sys_epoll_create, a)
WRAP6(sys_dup3, a, b, c)
WRAP6(sys_pipe2, a, b)
WRAP6(sys_prlimit64, a, b, c, d)
WRAP6(sys_sendmmsg, a, b, c, d)
WRAP6(sys_renameat2, a, b, c, d, e)
WRAP6(sys_getrandom, a, b, c)
WRAP6(sys_socket, a, b, c)
WRAP6(sys_socketpair, a, b, c, d)
WRAP6(sys_bind, a, b, c)
WRAP6(sys_connect, a, b, c)
WRAP6(sys_listen, a, b)
WRAP6(sys_getsockopt, a, b, c, d, e)
WRAP6(sys_setsockopt, a, b, c, d, e)
WRAP6(sys_getsockname, a, b, c)
WRAP6(sys_getpeername, a, b, c)
WRAP6(sys_sendmsg, a, b, c)
WRAP6(sys_recvmsg, a, b, c)
WRAP6(sys_shutdown, a, b)
WRAP6(sys_statx, a, b, c, d, e)
WRAP6(sys_arch_prctl, a, b)

// Stubs for unimplemented syscalls
WRAP6(syscall_stub)
WRAP6(syscall_silent_stub)
