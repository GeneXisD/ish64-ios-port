#include <stdio.h>
#include <string.h>
#include "linuxu.h"

extern int elf64_load_exec(const char *path);
extern void elf64_set_dryrun(int yes);
extern void proc_stub_dump(void);

int ishnext_boot(const char *arg0) {
    fprintf(stderr, "[ishnext] booting (host dev) — arg0=%s\n", arg0);
    proc_stub_dump();
    return 0;
}

int main(int argc, char **argv) {
    int dry = 0;
    for (int i=1;i<argc;i++) if (strcmp(argv[i], "--dryrun")==0) dry = 1;
    elf64_set_dryrun(dry);
    ishnext_boot(argv[0]);
    elf64_load_exec("assets/busybox-static-aarch64");
    return 0;
}
