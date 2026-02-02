#!/bin/sh
set -euo pipefail

APP_DIR=/opt/appliance
DATA_DIR=/var/lib/appliance
LOG_DIR=/var/log/appliance
CONFIG_DIR=/etc/appliance
REMOVE_DATA=${1:-""}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root." >&2
    exit 1
  fi
}

detect_init() {
  if [ -d /etc/runit ] && command -v sv >/dev/null 2>&1; then
    echo "runit"
  else
    echo "sysvinit"
  fi
}

require_root
INIT=$(detect_init)

if [ "$INIT" = "runit" ]; then
  for svc in djmount photoframe webui magicmirror calendar_fetch kiosk; do
    rm -f "/etc/service/$svc"
    rm -rf "/etc/sv/$svc"
  done
else
  for svc in djmount photoframe webui magicmirror calendar_fetch kiosk; do
    update-rc.d -f "$svc" remove >/dev/null 2>&1 || true
    rm -f "/etc/init.d/$svc"
  done
fi

rm -rf "$APP_DIR"

if [ "$REMOVE_DATA" = "--purge" ]; then
  rm -rf "$DATA_DIR" "$LOG_DIR" "$CONFIG_DIR"
fi

echo "Uninstall complete."
