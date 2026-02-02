#!/bin/sh
set -euo pipefail

CONFIG=/etc/appliance/appliance.yaml
LOG=/var/log/appliance/photoframe-watchdog.log

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG"
}

refresh_playlist() {
  /opt/appliance/venv/bin/python /opt/appliance/photoframe/playlist.py || true
}

while true; do
  refresh_playlist
  if ! /opt/appliance/photoframe/framectl.py status >/dev/null 2>&1; then
    /opt/appliance/photoframe/framectl.py start || log "failed to start mpv"
  fi
  refresh=$(/opt/appliance/venv/bin/python - <<'PY'
import yaml
cfg=yaml.safe_load(open('/etc/appliance/appliance.yaml'))
print(cfg['photoframe'].get('playlist_refresh_seconds',300))
PY
)
  sleep "$refresh"
done
