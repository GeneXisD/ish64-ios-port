#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "kernel/calls.h"
#include "kernel/task.h"
#include "xX_main_Xx.h"

int main(int argc, char *const argv[]) {

#ifdef SAFE_MODE
    printf("[ish64] SAFE MODE ACTIVE\n");
    return 0;
#endif

    // ✅ Single env string, compatible with xX_main_Xx
    const char *envp = getenv("TERM");
    if (!envp) envp = "TERM=xterm";

    printf("[ish64] Booting runtime...\n");

    int err = xX_main_Xx(argc, argv, envp);
    if (err < 0) {
        fprintf(stderr, "xX_main_Xx: %s\n", strerror(-err));
        return err;
    }

    printf("[ish64] Mounting filesystems...\n");

    do_mount(&procfs, "proc", "/proc", "", 0);
    do_mount(&devptsfs, "devpts", "/dev/pts", "", 0);

    printf("[ish64] Entering task loop...\n");

    task_run_current();

    return 0;
}
