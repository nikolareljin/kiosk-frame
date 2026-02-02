#!/bin/sh
set -euo pipefail

APP_DIR=/opt/appliance
CONFIG_DIR=/etc/appliance
DATA_DIR=/var/lib/appliance
LOG_DIR=/var/log/appliance
SECRETS_DIR=/etc/appliance/secrets
USER=frame

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

if ! id "$USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USER"
fi

mkdir -p "$APP_DIR" "$CONFIG_DIR" "$DATA_DIR" "$DATA_DIR/calendars" "$LOG_DIR" "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"
chown root:root "$SECRETS_DIR"

rsync -a --delete ./ "$APP_DIR/"

if [ ! -f "$CONFIG_DIR/appliance.yaml" ]; then
  cp "$APP_DIR/config/appliance.yaml.example" "$CONFIG_DIR/appliance.yaml"
fi

python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

if [ -d "$APP_DIR/mirror" ]; then
  "$APP_DIR/venv/bin/python" "$APP_DIR/mirror/render_config.py" || true
fi

INIT=$(detect_init)

if [ "$INIT" = "runit" ]; then
  for svc in djmount photoframe webui magicmirror calendar_fetch kiosk; do
    mkdir -p "/etc/sv/$svc"
    cp -r "$APP_DIR/services/runit/$svc/"* "/etc/sv/$svc/"
    chmod +x "/etc/sv/$svc/run"
    ln -sf "/etc/sv/$svc" "/etc/service/$svc"
  done
else
  for svc in djmount photoframe webui magicmirror calendar_fetch kiosk; do
    cp "$APP_DIR/services/sysvinit/$svc.init" "/etc/init.d/$svc"
    chmod +x "/etc/init.d/$svc"
    update-rc.d "$svc" defaults >/dev/null 2>&1 || true
  done
fi

chmod +x "$APP_DIR"/photoframe/*.py "$APP_DIR"/photoframe/*.sh
chmod +x "$APP_DIR"/calendar_fetch/fetcher.py
chmod +x "$APP_DIR"/mirror/*.sh "$APP_DIR"/mirror/render_config.py
chmod +x "$APP_DIR"/kiosk/*.sh
chmod +x "$APP_DIR"/webui/app.py

cat <<EON
Install complete.
Web UI: http://<host>:8080/
Config: $CONFIG_DIR/appliance.yaml
Logs: $LOG_DIR
EON
