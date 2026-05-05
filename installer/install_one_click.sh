#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

apt-get update -y
apt-get install -y curl gnupg ca-certificates unzip git ufw

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi

if ! command -v mongod >/dev/null 2>&1; then
  curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
  echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME)/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list
  apt-get update -y
  apt-get install -y mongodb-org
fi

systemctl enable mongod
systemctl restart mongod
npm i -g genieacs

id -u genieacs >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin genieacs
mkdir -p /opt/genieacs/ext /var/log/genieacs
chown -R genieacs:genieacs /opt/genieacs /var/log/genieacs

if [ -f "$ROOT_DIR/service/genieacs.env" ]; then
  cp "$ROOT_DIR/service/genieacs.env" /opt/genieacs/genieacs.env
elif [ -f "$ROOT_DIR/service/genieacs.env.example" ]; then
  cp "$ROOT_DIR/service/genieacs.env.example" /opt/genieacs/genieacs.env
else
  cat > /opt/genieacs/genieacs.env <<ENV
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.log
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=change_me
ENV
fi

if ls "$ROOT_DIR/service"/genieacs-*.service >/dev/null 2>&1; then
  cp "$ROOT_DIR/service"/genieacs-*.service /etc/systemd/system/
fi

if [ -f "$ROOT_DIR/custom-ui/app-FOJWPRV7.js" ]; then
  cp "$ROOT_DIR/custom-ui/app-FOJWPRV7.js" /usr/lib/node_modules/genieacs/public/
fi
if [ -f "$ROOT_DIR/custom-ui/app-LU66VFYW.css" ]; then
  cp "$ROOT_DIR/custom-ui/app-LU66VFYW.css" /usr/lib/node_modules/genieacs/public/
fi
if [ -f "$ROOT_DIR/custom-ui/index.html" ]; then
  cp "$ROOT_DIR/custom-ui/index.html" /usr/lib/node_modules/genieacs/public/
fi

ufw allow 7547/tcp || true
ufw allow 7557/tcp || true
ufw allow 7567/tcp || true
ufw allow 3000/tcp || true

if [ "${RESTORE_DB:-0}" = "1" ] && [ -f "$ROOT_DIR/backup/genieacs_mongo.archive" ]; then
  mongorestore --gzip --archive="$ROOT_DIR/backup/genieacs_mongo.archive" --drop || true
fi

systemctl daemon-reload
systemctl enable genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
systemctl restart genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

echo "DONE: GenieACS installed."
