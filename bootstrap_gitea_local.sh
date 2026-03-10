#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/gitea-ish64"
STACK_DIR="${BASE_DIR}/stack"
DATA_DIR="${BASE_DIR}/data"
CONFIG_DIR="${BASE_DIR}/config"
HOST_WEB_PORT="${HOST_WEB_PORT:-3000}"
HOST_SSH_PORT="${HOST_SSH_PORT:-2222}"
GITEA_IMAGE="${GITEA_IMAGE:-docker.gitea.com/gitea:latest-rootless}"

echo "[*] Checking dependencies..."
command -v docker >/dev/null 2>&1 || { echo "Docker is required."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker daemon is not running."; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Docker Compose v2 is required."; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git is required."; exit 1; }

echo "[*] Creating directories..."
mkdir -p "${STACK_DIR}" "${DATA_DIR}" "${CONFIG_DIR}"

COMPOSE_FILE="${STACK_DIR}/docker-compose.yml"

echo "[*] Writing ${COMPOSE_FILE}..."
cat > "${COMPOSE_FILE}" <<EOF
services:
  gitea:
    image: ${GITEA_IMAGE}
    container_name: gitea-ish64
    restart: unless-stopped
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__server__DOMAIN=localhost
      - GITEA__server__SSH_DOMAIN=localhost
      - GITEA__server__ROOT_URL=http://localhost:${HOST_WEB_PORT}/
      - GITEA__server__HTTP_PORT=3000
      - GITEA__server__SSH_PORT=${HOST_SSH_PORT}
      - GITEA__database__DB_TYPE=sqlite3
      - GITEA__service__DISABLE_REGISTRATION=false
      - GITEA__service__REQUIRE_SIGNIN_VIEW=false
      - GITEA__repository__DEFAULT_BRANCH=main
      - GITEA__security__INSTALL_LOCK=false
    ports:
      - "${HOST_WEB_PORT}:3000"
      - "${HOST_SSH_PORT}:2222"
    volumes:
      - ${DATA_DIR}:/var/lib/gitea
      - ${CONFIG_DIR}:/etc/gitea
EOF

echo "[*] Starting Gitea..."
cd "${STACK_DIR}"
docker compose up -d

echo
echo "[+] Gitea is starting."
echo "[+] Open: http://localhost:${HOST_WEB_PORT}"
echo "[+] On first load, complete the web installer."
echo
echo "[+] Suggested first-run values:"
echo "    Site Title: ish64 Forge"
echo "    SSH Server Domain: localhost"
echo "    SSH Server Port: ${HOST_SSH_PORT}"
echo "    Gitea Base URL: http://localhost:${HOST_WEB_PORT}/"
echo
echo "[+] After you create your first admin user, lock registration:"
echo "    docker exec gitea-ish64 sh -lc 'grep -q \"DISABLE_REGISTRATION\" /etc/gitea/app.ini || true'"
echo "    Then edit ${CONFIG_DIR}/app.ini and set:"
echo "      [service]"
echo "      DISABLE_REGISTRATION = true"
echo "      REQUIRE_SIGNIN_VIEW = true"
echo "    Restart with:"
echo "      cd ${STACK_DIR} && docker compose restart"
echo
echo "[+] Backup paths:"
echo "    Data:   ${DATA_DIR}"
echo "    Config: ${CONFIG_DIR}"

