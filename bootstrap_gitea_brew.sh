#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/gitea"
CUSTOM="${BASE}/custom"
DATA="${BASE}/data"
LOGDIR="${BASE}/log"
APPINI="${CUSTOM}/conf/app.ini"
WEB_PORT="${WEB_PORT:-3000}"
SSH_PORT="${SSH_PORT:-2222}"

command -v gitea >/dev/null 2>&1 || {
  echo "gitea is not installed. Run: brew install gitea"
  exit 1
}

mkdir -p "${CUSTOM}/conf" "${DATA}" "${LOGDIR}"

if [ ! -f "${APPINI}" ]; then
  cat > "${APPINI}" <<EOF
APP_NAME = ish64 Forge
RUN_USER = $(whoami)
RUN_MODE = prod

[database]
DB_TYPE = sqlite3
PATH = ${DATA}/gitea.db

[repository]
ROOT = ${DATA}/gitea-repositories
DEFAULT_BRANCH = main

[server]
DOMAIN = localhost
HTTP_ADDR = 127.0.0.1
HTTP_PORT = ${WEB_PORT}
ROOT_URL = http://localhost:${WEB_PORT}/
DISABLE_SSH = false
SSH_DOMAIN = localhost
START_SSH_SERVER = true
SSH_PORT = ${SSH_PORT}
SSH_LISTEN_PORT = ${SSH_PORT}
LFS_START_SERVER = true
OFFLINE_MODE = false

[service]
DISABLE_REGISTRATION = false
REQUIRE_SIGNIN_VIEW = false

[security]
INSTALL_LOCK = false

[log]
ROOT_PATH = ${LOGDIR}
MODE = console,file
LEVEL = Info
EOF
fi

echo "[*] Starting Gitea..."
nohup gitea web --config "${APPINI}" > "${LOGDIR}/gitea-console.log" 2>&1 &
sleep 2

echo
echo "[+] Gitea should be starting at: http://localhost:${WEB_PORT}"
echo "[+] Config: ${APPINI}"
echo "[+] Log:    ${LOGDIR}/gitea-console.log"
echo
echo "[+] First-run plan:"
echo "    1. Open http://localhost:${WEB_PORT}"
echo "    2. Complete the installer"
echo "    3. Create your admin user"
echo "    4. Then lock registration in:"
echo "       ${APPINI}"
echo
echo "       [service]"
echo "       DISABLE_REGISTRATION = true"
echo "       REQUIRE_SIGNIN_VIEW = true"
echo
echo "[+] To stop Gitea later:"
echo "    pkill -f 'gitea web --config ${APPINI}'"
