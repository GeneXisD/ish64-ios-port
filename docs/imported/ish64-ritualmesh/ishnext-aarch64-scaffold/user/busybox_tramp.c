// user/busybox_tramp.c
#include <stdio.h>

// Provided by libbusybox when built with CONFIG_FEATURE_LIBBUSYBOX
int busybox_main(int argc, char **argv);

int ishnext_shell(void) {
    char *argv[] = { "busybox", "sh", NULL };
    fprintf(stderr, "[ishnext] launching busybox shell (embedded)\n");
    return busybox_main(2, argv);
}
