project(
  'ish',
  'c',
  default_options: [
    'default_library=static',
    'c_std=gnu11',
    'warning_level=2'
  ]
)

cc = meson.get_compiler('c')

if cc.get_id() == 'clang'
    add_project_arguments('-Wimplicit-fallthrough', '-Wtautological-constant-in-range-compare', language: 'c')
endif

add_project_arguments('-Wno-switch', language: 'c')

includes = [include_directories('.')]

threads = dependency('threads')
librt = cc.find_library('rt', required: false)
libm = cc.find_library('m', required: false)
libdl = cc.find_library('dl', required: false)
sqlite3 = cc.find_library('sqlite3')

dependencies = [librt, libm, libdl, threads, sqlite3]

# --- VDSO (force stub on macOS) ---
vdso_srcs = ['kernel/vdso_stub.c']
message('Using VDSO stub on non-Linux host')

# --- Minimal EMU (NO asbestos JIT) ---
emu_src = [
    'emu/tlb.c',
    'emu/fpu.c',
    'emu/vec.c',
    'emu/mmx.c',
    'emu/float80.c',

    # Stub asbestos only
    'asbestos/asbestos.c',
]

libish_emu = library('ish_emu', emu_src, include_directories: includes)

# --- Fake FS ---
libfakefs = library('fakefs',
    [
        'fs/fake-db.c',
        'fs/fake-migrate.c',
        'fs/fake-rebuild.c'
    ],
    include_directories: includes,
    dependencies: sqlite3
)

subdir('deps')

# --- Kernel (ISH mode only) ---
src = [
    'stub_runtime.c',
    'kernel/init.c',
    'syscall_wrappers.c',
    'kernel/cpu_stub.c',
    'kernel/mm_stub.c',
    'kernel/lock_stub.c',
    'kernel/errno.c',

    'kernel/calls.c',
    'kernel/memory.c',
    'kernel/user.c',
    'kernel/task.c',
    'kernel/group.c',
    'kernel/log.c',
    'kernel/fork.c',
    'kernel/exec.c',
    'kernel/exit.c',
    'kernel/time.c',
    'kernel/mmap.c',
    'kernel/uname.c',
    'kernel/tls.c',
    'kernel/futex.c',
    'kernel/getset.c',
    'kernel/signal.c',
    'kernel/resource.c',
    'kernel/random.c',
    'kernel/misc.c',
    'kernel/eventfd.c',
    'kernel/ipc.c',
    'kernel/ptrace.c',

    vdso_srcs,

    'kernel/fs.c',
    'kernel/fs_info.c',

    'fs/mount.c',
    'fs/fd.c',
    'fs/inode.c',
    'fs/stat.c',
    'fs/dir.c',
    'fs/generic.c',
    'fs/path.c',
    'fs/real.c',
    'fs/fake.c',

    'fs/proc.c',
    'fs/proc/entry.c',
    'fs/proc/ish.c',
    'fs/proc/root.c',
    'fs/proc/pid.c',

    'fs/dyndev.c',

    'fs/adhoc.c',
    'fs/sock.c',
    'fs/pipe.c',
    'fs/sockrestart.c',
    'fs/lock.c',

    'fs/dev.c',
    'fs/mem.c',
    'fs/tty.c',
    'fs/tty-real.c',
    'fs/pty.c',
    'fs/tmp.c',

    'fs/poll.c',
    'kernel/poll.c',
    'kernel/epoll.c',

    'util/timer.c',
    'util/sync.c',
    'util/fifo.c',
    'util/fchdir.c',

    'platform/' + host_machine.system() + '.c',
]

libish = library('ish', src, include_directories: includes)

ish_dep = declare_dependency(
    link_with: [libish, libish_emu, libfakefs],
    dependencies: dependencies,
    include_directories: includes
)

if not meson.is_cross_build()
    executable('ish', ['main.c'], dependencies: ish_dep)
endif

subdir('tools')
