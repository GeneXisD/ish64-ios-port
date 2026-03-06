#!/bin/bash
# fix_slirp_ios.sh
# Applies automated fixes for compiling slirp on iOS arm64

set -e

PROJECT_DIR="$HOME/Projects/ish64/emu/tinyemu/slirp"
BACKUP_DIR="$PROJECT_DIR/backup_$(date +%s)"

echo "Creating backup at $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp "$PROJECT_DIR"/*.c "$PROJECT_DIR"/*.h "$BACKUP_DIR"

echo "Fixing macro redefinitions..."
for header in "$PROJECT_DIR"/../*.h; do
    sed -i '' 's/^#define unlikely/#ifndef unlikely\n#define unlikely/' "$header"
    sed -i '' 's/^#define glue/#ifndef glue\n#define glue/' "$header"
done

echo "Fixing slirp function signatures in slirp.c..."
sed -i '' 's/^void slirp_select_fill(Slirp.*$/void slirp_select_fill(Slirp *slirp, int *pnfds, fd_set *readfds, fd_set *writefds)/' "$PROJECT_DIR/slirp.c"
sed -i '' 's/^void slirp_select_poll(Slirp.*$/void slirp_select_poll(Slirp *slirp, fd_set *readfds, fd_set *writefds, int *ready)/' "$PROJECT_DIR/slirp.c"

echo "Adding necessary headers for errno/socket constants..."
grep -q '#include <errno.h>' "$PROJECT_DIR/slirp.c" || sed -i '' '1i\
#include <errno.h>\
#include <sys/types.h>\
#include <sys/socket.h>\
#include <netinet/in.h>\
#include <arpa/inet.h>\
#include <unistd.h>' "$PROJECT_DIR/slirp.c"

echo "Applying 64→32-bit cast for send() return value..."
sed -i '' 's/\(ret = send(so->s,.*\))/ret = (int) \1/' "$PROJECT_DIR/slirp.c"

echo "Done! Backup of original files is in $BACKUP_DIR"
echo "You can now try building again in Xcode."
