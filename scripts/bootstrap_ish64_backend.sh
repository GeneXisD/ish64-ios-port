#!/usr/bin/env bash
set -euo pipefail

# bootstrap_ish64_backend.sh
# Creates a backend-driven scaffold for ish64 inside an iSH-style repo.

ROOT_DIR="${1:-$(pwd)}"
PROJECT_NAME="${PROJECT_NAME:-iSH.xcodeproj}"
PBXPROJ_PATH="$ROOT_DIR/$PROJECT_NAME/project.pbxproj"

say() { printf "\n[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

[ -d "$ROOT_DIR" ] || die "Root dir not found: $ROOT_DIR"
[ -d "$ROOT_DIR/$PROJECT_NAME" ] || die "Xcode project not found: $ROOT_DIR/$PROJECT_NAME"

mkdir -p \
  "$ROOT_DIR/backend" \
  "$ROOT_DIR/rootfs" \
  "$ROOT_DIR/loader" \
  "$ROOT_DIR/app" \
  "$ROOT_DIR/scripts"

backup_project() {
  if [ -f "$PBXPROJ_PATH" ]; then
    cp "$PBXPROJ_PATH" "$PBXPROJ_PATH.bak.$(date +%Y%m%d-%H%M%S)"
    say "Backed up project.pbxproj"
  fi
}

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  say "Wrote ${path#$ROOT_DIR/}"
}

say "Creating ish64 backend scaffold in: $ROOT_DIR"
backup_project

write_file "$ROOT_DIR/backend/backend.h" <<'EOF'
#ifndef ISH_BACKEND_H
#define ISH_BACKEND_H

#ifdef __cplusplus
extern "C" {
#endif

struct vm_backend;

typedef enum {
    BACKEND_KIND_ISH_X86 = 0,
    BACKEND_KIND_LINUX64_STUB = 1,
    BACKEND_KIND_LINUX64_AARCH64 = 2,
    BACKEND_KIND_LINUX64_X86_64 = 3,
} backend_kind_t;

typedef struct vm_backend {
    const char *name;
    backend_kind_t kind;

    int (*init)(void);
    int (*load_rootfs)(const char *path);
    int (*spawn)(const char *path, char *const argv[], char *const envp[]);
    int (*step)(void);
    int (*handle_signal)(int sig);
    void (*shutdown)(void);
} vm_backend_t;

const vm_backend_t *backend_get_default(void);
const vm_backend_t *backend_get_by_kind(backend_kind_t kind);
const vm_backend_t *backend_get_by_name(const char *name);

int backend_set_active(const vm_backend_t *backend);
const vm_backend_t *backend_get_active(void);

int backend_init_active(void);
int backend_load_rootfs_active(const char *path);
int backend_spawn_active(const char *path, char *const argv[], char *const envp[]);
int backend_step_active(void);
int backend_handle_signal_active(int sig);
void backend_shutdown_active(void);

const vm_backend_t *backend_ish_x86(void);
const vm_backend_t *backend_linux64_stub(void);
const vm_backend_t *backend_linux64_aarch64(void);
const vm_backend_t *backend_linux64_x86_64(void);

#ifdef __cplusplus
}
#endif

#endif
EOF

write_file "$ROOT_DIR/backend/backend_registry.c" <<'EOF'
#include "backend.h"

#include <stddef.h>
#include <string.h>

static const vm_backend_t *g_active_backend = NULL;

static const vm_backend_t *all_backends[] = {
    NULL,
    NULL,
    NULL,
    NULL,
};

static void backend_registry_bootstrap(void) {
    if (all_backends[0] != NULL)
        return;

    all_backends[0] = backend_ish_x86();
    all_backends[1] = backend_linux64_stub();
    all_backends[2] = backend_linux64_aarch64();
    all_backends[3] = backend_linux64_x86_64();

    if (g_active_backend == NULL)
        g_active_backend = all_backends[0];
}

const vm_backend_t *backend_get_default(void) {
    backend_registry_bootstrap();
    return all_backends[0];
}

const vm_backend_t *backend_get_by_kind(backend_kind_t kind) {
    backend_registry_bootstrap();

    for (size_t i = 0; i < sizeof(all_backends) / sizeof(all_backends[0]); i++) {
        if (all_backends[i] != NULL && all_backends[i]->kind == kind)
            return all_backends[i];
    }
    return NULL;
}

const vm_backend_t *backend_get_by_name(const char *name) {
    backend_registry_bootstrap();
    if (name == NULL)
        return NULL;

    for (size_t i = 0; i < sizeof(all_backends) / sizeof(all_backends[0]); i++) {
        if (all_backends[i] != NULL && all_backends[i]->name != NULL &&
            strcmp(all_backends[i]->name, name) == 0)
            return all_backends[i];
    }
    return NULL;
}

int backend_set_active(const vm_backend_t *backend) {
    backend_registry_bootstrap();
    if (backend == NULL)
        return -1;
    g_active_backend = backend;
    return 0;
}

const vm_backend_t *backend_get_active(void) {
    backend_registry_bootstrap();
    return g_active_backend;
}

int backend_init_active(void) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->init) ? b->init() : -1;
}

int backend_load_rootfs_active(const char *path) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->load_rootfs) ? b->load_rootfs(path) : -1;
}

int backend_spawn_active(const char *path, char *const argv[], char *const envp[]) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->spawn) ? b->spawn(path, argv, envp) : -1;
}

int backend_step_active(void) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->step) ? b->step() : -1;
}

int backend_handle_signal_active(int sig) {
    const vm_backend_t *b = backend_get_active();
    return (b && b->handle_signal) ? b->handle_signal(sig) : -1;
}

void backend_shutdown_active(void) {
    const vm_backend_t *b = backend_get_active();
    if (b && b->shutdown)
        b->shutdown();
}
EOF

write_file "$ROOT_DIR/backend/backend_ish_x86.c" <<'EOF'
#include "backend.h"

/*
 * Adapter layer for the current iSH execution core.
 * Replace the TODO sections with calls into the existing emulator path.
 */

static int ish_x86_init(void) {
    return 0;
}

static int ish_x86_load_rootfs(const char *path) {
    (void) path;
    return 0;
}

static int ish_x86_spawn(const char *path, char *const argv[], char *const envp[]) {
    (void) path;
    (void) argv;
    (void) envp;
    return 0;
}

static int ish_x86_step(void) {
    return 0;
}

static int ish_x86_handle_signal(int sig) {
    (void) sig;
    return 0;
}

static void ish_x86_shutdown(void) {
}

static const vm_backend_t BACKEND = {
    .name = "ish-x86",
    .kind = BACKEND_KIND_ISH_X86,
    .init = ish_x86_init,
    .load_rootfs = ish_x86_load_rootfs,
    .spawn = ish_x86_spawn,
    .step = ish_x86_step,
    .handle_signal = ish_x86_handle_signal,
    .shutdown = ish_x86_shutdown,
};

const vm_backend_t *backend_ish_x86(void) {
    return &BACKEND;
}
EOF

write_file "$ROOT_DIR/backend/backend_linux64_stub.c" <<'EOF'
#include "backend.h"

#include <errno.h>

static int linux64_stub_init(void) {
    return 0;
}

static int linux64_stub_load_rootfs(const char *path) {
    (void) path;
    return 0;
}

static int linux64_stub_spawn(const char *path, char *const argv[], char *const envp[]) {
    (void) path;
    (void) argv;
    (void) envp;
    errno = ENOSYS;
    return -1;
}

static int linux64_stub_step(void) {
    errno = ENOSYS;
    return -1;
}

static int linux64_stub_handle_signal(int sig) {
    (void) sig;
    errno = ENOSYS;
    return -1;
}

static void linux64_stub_shutdown(void) {
}

static const vm_backend_t BACKEND = {
    .name = "linux64-stub",
    .kind = BACKEND_KIND_LINUX64_STUB,
    .init = linux64_stub_init,
    .load_rootfs = linux64_stub_load_rootfs,
    .spawn = linux64_stub_spawn,
    .step = linux64_stub_step,
    .handle_signal = linux64_stub_handle_signal,
    .shutdown = linux64_stub_shutdown,
};

const vm_backend_t *backend_linux64_stub(void) {
    return &BACKEND;
}
EOF

write_file "$ROOT_DIR/backend/backend_linux64_aarch64.c" <<'EOF'
#include "backend.h"

#include <errno.h>

static int linux64_aarch64_init(void) {
    return 0;
}

static int linux64_aarch64_load_rootfs(const char *path) {
    (void) path;
    return 0;
}

static int linux64_aarch64_spawn(const char *path, char *const argv[], char *const envp[]) {
    (void) path;
    (void) argv;
    (void) envp;
    errno = ENOSYS;
    return -1;
}

static int linux64_aarch64_step(void) {
    errno = ENOSYS;
    return -1;
}

static int linux64_aarch64_handle_signal(int sig) {
    (void) sig;
    errno = ENOSYS;
    return -1;
}

static void linux64_aarch64_shutdown(void) {
}

static const vm_backend_t BACKEND = {
    .name = "linux64-aarch64",
    .kind = BACKEND_KIND_LINUX64_AARCH64,
    .init = linux64_aarch64_init,
    .load_rootfs = linux64_aarch64_load_rootfs,
    .spawn = linux64_aarch64_spawn,
    .step = linux64_aarch64_step,
    .handle_signal = linux64_aarch64_handle_signal,
    .shutdown = linux64_aarch64_shutdown,
};

const vm_backend_t *backend_linux64_aarch64(void) {
    return &BACKEND;
}
EOF

write_file "$ROOT_DIR/backend/backend_linux64_x86_64.c" <<'EOF'
#include "backend.h"

#include <errno.h>

static int linux64_x86_64_init(void) {
    return 0;
}

static int linux64_x86_64_load_rootfs(const char *path) {
    (void) path;
    return 0;
}

static int linux64_x86_64_spawn(const char *path, char *const argv[], char *const envp[]) {
    (void) path;
    (void) argv;
    (void) envp;
    errno = ENOSYS;
    return -1;
}

static int linux64_x86_64_step(void) {
    errno = ENOSYS;
    return -1;
}

static int linux64_x86_64_handle_signal(int sig) {
    (void) sig;
    errno = ENOSYS;
    return -1;
}

static void linux64_x86_64_shutdown(void) {
}

static const vm_backend_t BACKEND = {
    .name = "linux64-x86_64",
    .kind = BACKEND_KIND_LINUX64_X86_64,
    .init = linux64_x86_64_init,
    .load_rootfs = linux64_x86_64_load_rootfs,
    .spawn = linux64_x86_64_spawn,
    .step = linux64_x86_64_step,
    .handle_signal = linux64_x86_64_handle_signal,
    .shutdown = linux64_x86_64_shutdown,
};

const vm_backend_t *backend_linux64_x86_64(void) {
    return &BACKEND;
}
EOF

write_file "$ROOT_DIR/rootfs/rootfs_manifest.h" <<'EOF'
#ifndef ISH_ROOTFS_MANIFEST_H
#define ISH_ROOTFS_MANIFEST_H

#include "../backend/backend.h"

typedef struct rootfs_manifest {
    char name[64];
    char arch[32];
    char abi[32];
    char backend_name[64];
    char init_path[256];
} rootfs_manifest_t;

int rootfs_manifest_load(const char *rootfs_dir, rootfs_manifest_t *out_manifest);
const vm_backend_t *rootfs_manifest_select_backend(const rootfs_manifest_t *manifest);

#endif
EOF

write_file "$ROOT_DIR/rootfs/rootfs_manifest.c" <<'EOF'
#include "rootfs_manifest.h"

#include <stdio.h>
#include <string.h>

int rootfs_manifest_load(const char *rootfs_dir, rootfs_manifest_t *out_manifest) {
    (void) rootfs_dir;
    if (out_manifest == NULL)
        return -1;

    memset(out_manifest, 0, sizeof(*out_manifest));
    snprintf(out_manifest->name, sizeof(out_manifest->name), "%s", "Default RootFS");
    snprintf(out_manifest->arch, sizeof(out_manifest->arch), "%s", "x86");
    snprintf(out_manifest->abi, sizeof(out_manifest->abi), "%s", "linux");
    snprintf(out_manifest->backend_name, sizeof(out_manifest->backend_name), "%s", "ish-x86");
    snprintf(out_manifest->init_path, sizeof(out_manifest->init_path), "%s", "/bin/sh");
    return 0;
}

const vm_backend_t *rootfs_manifest_select_backend(const rootfs_manifest_t *manifest) {
    if (manifest == NULL)
        return backend_get_default();

    const vm_backend_t *backend = backend_get_by_name(manifest->backend_name);
    return backend ? backend : backend_get_default();
}
EOF

write_file "$ROOT_DIR/loader/elf64.h" <<'EOF'
#ifndef ISH_ELF64_H
#define ISH_ELF64_H

#include <stdint.h>

typedef struct elf64_image {
    uint64_t entry;
    uint64_t phoff;
    uint16_t phnum;
    uint16_t machine;
} elf64_image_t;

int elf64_load_image(const char *path, elf64_image_t *out_image);

#endif
EOF

write_file "$ROOT_DIR/loader/elf64.c" <<'EOF'
#include "elf64.h"

#include <elf.h>
#include <stdio.h>
#include <string.h>

int elf64_load_image(const char *path, elf64_image_t *out_image) {
    if (path == NULL || out_image == NULL)
        return -1;

    FILE *fp = fopen(path, "rb");
    if (!fp)
        return -1;

    Elf64_Ehdr eh;
    memset(&eh, 0, sizeof(eh));

    if (fread(&eh, 1, sizeof(eh), fp) != sizeof(eh)) {
        fclose(fp);
        return -1;
    }

    fclose(fp);

    if (memcmp(eh.e_ident, ELFMAG, SELFMAG) != 0)
        return -1;
    if (eh.e_ident[EI_CLASS] != ELFCLASS64)
        return -1;

    memset(out_image, 0, sizeof(*out_image));
    out_image->entry = eh.e_entry;
    out_image->phoff = eh.e_phoff;
    out_image->phnum = eh.e_phnum;
    out_image->machine = eh.e_machine;
    return 0;
}
EOF

write_file "$ROOT_DIR/app/backend_bootstrap.c" <<'EOF'
#include "../backend/backend.h"
#include "../rootfs/rootfs_manifest.h"

int ish_backend_bootstrap(const char *rootfs_dir) {
    rootfs_manifest_t manifest;
    if (rootfs_manifest_load(rootfs_dir, &manifest) != 0)
        return -1;

    const vm_backend_t *backend = rootfs_manifest_select_backend(&manifest);
    if (backend_set_active(backend) != 0)
        return -1;

    if (backend_init_active() != 0)
        return -1;

    if (backend_load_rootfs_active(rootfs_dir) != 0)
        return -1;

    return 0;
}
EOF

write_file "$ROOT_DIR/app/backend_bootstrap.h" <<'EOF'
#ifndef ISH_BACKEND_BOOTSTRAP_H
#define ISH_BACKEND_BOOTSTRAP_H

int ish_backend_bootstrap(const char *rootfs_dir);

#endif
EOF

write_file "$ROOT_DIR/rootfs/manifest.json.example" <<'EOF'
{
  "name": "Default RootFS",
  "arch": "x86",
  "abi": "linux",
  "backend": "ish-x86",
  "init": "/bin/sh"
}
EOF

write_file "$ROOT_DIR/scripts/add_backend_scaffold_to_xcode.rb" <<'EOF'
#!/usr/bin/env ruby
require "pathname"

begin
  require "xcodeproj"
rescue LoadError
  warn "xcodeproj gem is not installed. Install it with: gem install xcodeproj"
  exit 2
end

root = Pathname.new(ARGV[0] || Dir.pwd)
project_path = root.join("iSH.xcodeproj")
abort("Missing #{project_path}") unless project_path.exist?

project = Xcodeproj::Project.open(project_path.to_s)

group_backend = project.main_group.find_subpath("backend", true)
group_rootfs  = project.main_group.find_subpath("rootfs", true)
group_loader  = project.main_group.find_subpath("loader", true)
group_app     = project.main_group.find_subpath("app", true)

files = {
  group_backend => %w[
    backend/backend.h
    backend/backend_registry.c
    backend/backend_ish_x86.c
    backend/backend_linux64_stub.c
    backend/backend_linux64_aarch64.c
    backend/backend_linux64_x86_64.c
  ],
  group_rootfs => %w[
    rootfs/rootfs_manifest.h
    rootfs/rootfs_manifest.c
  ],
  group_loader => %w[
    loader/elf64.h
    loader/elf64.c
  ],
  group_app => %w[
    app/backend_bootstrap.h
    app/backend_bootstrap.c
  ]
}

targets = project.targets.select { |t| ["iSH", "libiSHApp", "libish", "libish_emu", "iSHFileProvider"].include?(t.name) }

files.each do |group, paths|
  paths.each do |rel|
    ref = group.files.find { |f| f.path == rel } || group.new_file(rel)
    ext = File.extname(rel)
    next if ext == ".h"
    targets.each do |target|
      phase = target.source_build_phase
      unless phase.files_references.include?(ref)
        phase.add_file_reference(ref, true)
      end
    end
  end
end

project.save
puts "Updated #{project_path}"
EOF
chmod +x "$ROOT_DIR/scripts/add_backend_scaffold_to_xcode.rb"

write_file "$ROOT_DIR/scripts/build_ish64_scaffold.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
xcodebuild \
  -project iSH.xcodeproj \
  -scheme iSH \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  clean build
EOF
chmod +x "$ROOT_DIR/scripts/build_ish64_scaffold.sh"

if command -v ruby >/dev/null 2>&1; then
  if ruby -e 'require "xcodeproj"' >/dev/null 2>&1; then
    say "Adding files to Xcode project via xcodeproj gem"
    (cd "$ROOT_DIR" && ruby scripts/add_backend_scaffold_to_xcode.rb "$ROOT_DIR")
  else
    say "Ruby found, but xcodeproj gem missing"
    echo "Install with: gem install xcodeproj"
  fi
else
  say "Ruby not found; skipping automatic Xcode project wiring"
fi

say "Scaffold complete"

cat <<'EOF'

Next steps:
1. Open Xcode and confirm the new files appear in the project.
2. Build once:
   ./scripts/build_ish64_scaffold.sh
3. Wire your current iSH startup path into:
   app/backend_bootstrap.c
4. Then replace direct process launch calls with:
   backend_spawn_active(...)

Good first check:
- the app should still build with default backend "ish-x86"
- no runtime behavior should change yet
EOF

