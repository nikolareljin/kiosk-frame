#!/bin/sh
set -euo pipefail

xset s off
xset -dpms
xset s noblank

URL=$(/opt/appliance/venv/bin/python - <<'PY'
import yaml
cfg=yaml.safe_load(open('/etc/appliance/appliance.yaml'))
print(cfg['kiosk'].get('url','http://localhost:8080/'))
PY
)

CHROMIUM=$(command -v chromium || command -v chromium-browser || true)
if [ -z "$CHROMIUM" ]; then
  echo "Chromium not found" >&2
  exit 1
fi

exec "$CHROMIUM" \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --autoplay-policy=no-user-gesture-required \
  "$URL"
