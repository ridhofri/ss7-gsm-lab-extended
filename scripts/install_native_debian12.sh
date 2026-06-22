#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

echo "[1/5] Adding Osmocom repo (Debian 12)..."
cat >/etc/apt/sources.list.d/osmocom-latest.list <<'EOF'
deb [trusted=yes] https://downloads.osmocom.org/packages/osmocom:/latest/Debian_12 ./
EOF

echo "[2/5] apt update..."
apt-get update

echo "[3/5] Install core packages..."
apt-get install -y \
  osmo-msc osmo-hlr osmo-stp osmo-mgw \
  tmux sqlite3 iproute2 net-tools

echo "[4/5] Create runtime dirs..."
install -d -m 0755 /opt/ss7lab/config /opt/ss7lab/logs

echo "[5/5] Copy example configs..."
cp -av config/* /opt/ss7lab/config/ 2>/dev/null || true
echo "Done. Configs are in /opt/ss7lab/config"
echo
echo ">> If you hit libortp/libosmotrau dependency problems, use Docker (docker/docker-compose.yml)."
