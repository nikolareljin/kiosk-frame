#!/usr/bin/env bash
set -euo pipefail

APP_DIR=/opt/appliance
CONFIG_DIR=/etc/appliance
DATA_DIR=/var/lib/appliance
LOG_DIR=/var/log/appliance
SECRETS_DIR=/etc/appliance/secrets
KIOSK_USER=frame

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_HELPERS_DIR="${SCRIPT_HELPERS_DIR:-$SCRIPT_DIR/vendor/script-helpers}"

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

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

bootstrap_dialog() {
  if ! command -v dialog >/dev/null 2>&1; then
    echo "Installing dialog..." >&2
    apt-get update -qq && apt-get install -y dialog >/dev/null 2>&1
  fi
}

load_helpers() {
  if [[ ! -f "$SCRIPT_HELPERS_DIR/helpers.sh" ]]; then
    echo "script-helpers not found at $SCRIPT_HELPERS_DIR." >&2
    echo "Run: git submodule update --init --recursive" >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$SCRIPT_HELPERS_DIR/helpers.sh"
  shlib_import logging dialog deps
}

reset_tui() { tput cnorm 2>/dev/null || true; clear; }
trap reset_tui EXIT INT TERM

# ---------------------------------------------------------------------------
# Component installers
# ---------------------------------------------------------------------------

install_core() {
  print_info "Installing core..."

  if ! id "$KIOSK_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$KIOSK_USER"
  fi

  mkdir -p "$APP_DIR" "$CONFIG_DIR" "$DATA_DIR" "$DATA_DIR/calendars" \
            "$LOG_DIR" "$SECRETS_DIR"
  chmod 700 "$SECRETS_DIR"
  chown root:root "$SECRETS_DIR"

  rsync -a --delete "$SCRIPT_DIR/" "$APP_DIR/"

  if [ ! -f "$CONFIG_DIR/appliance.yaml" ]; then
    cp "$APP_DIR/config/appliance.yaml.example" "$CONFIG_DIR/appliance.yaml"
  fi

  python3 -m venv "$APP_DIR/venv"
  "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt" -q
}

install_photoframe() {
  print_info "Installing photoframe (djmount + mpv)..."
  apt-get install -y djmount mpv ffmpeg fuse >/dev/null 2>&1
  chmod +x "$APP_DIR"/photoframe/*.py "$APP_DIR"/photoframe/*.sh
  _register_service djmount
  _register_service photoframe
}

install_mirror() {
  print_info "Installing MagicMirror..."
  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    apt-get install -y nodejs npm >/dev/null 2>&1
  fi
  bash "$APP_DIR/mirror/install_magicmirror.sh" "$APP_DIR/magicmirror"
  chmod +x "$APP_DIR"/mirror/*.sh "$APP_DIR/mirror/render_config.py"
  "$APP_DIR/venv/bin/python" "$APP_DIR/mirror/render_config.py" || true
  _register_service magicmirror
}

install_calendar() {
  print_info "Installing calendar_fetch..."
  chmod +x "$APP_DIR/calendar_fetch/fetcher.py"
  _register_service calendar_fetch
}

install_webui() {
  print_info "Installing webui..."
  chmod +x "$APP_DIR/webui/app.py"
  _register_service webui
}

install_kiosk() {
  print_info "Installing kiosk (Chromium)..."
  if ! command -v chromium >/dev/null 2>&1 && ! command -v chromium-browser >/dev/null 2>&1; then
    apt-get install -y chromium >/dev/null 2>&1 \
      || apt-get install -y chromium-browser >/dev/null 2>&1 || true
  fi
  if ! command -v startx >/dev/null 2>&1; then
    apt-get install -y xinit xorg >/dev/null 2>&1
  fi
  chmod +x "$APP_DIR"/kiosk/*.sh
  _register_service kiosk
}

install_distrodeck() {
  print_info "Installing distrodeck..."
  local dest=/opt/distrodeck
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull -q
  else
    git clone --depth 1 https://github.com/nikolareljin/distrodeck.git "$dest"
  fi
  ln -sf "$dest/distrodeck" /usr/local/bin/distrodeck
  print_info "distrodeck -> /usr/local/bin/distrodeck"
}

install_ansible() {
  print_info "Installing ansible..."
  if ! command -v ansible >/dev/null 2>&1; then
    apt-get install -y ansible >/dev/null 2>&1
  fi
  ansible --version | head -1
}

_register_service() {
  local svc="$1"
  local init; init=$(detect_init)
  if [ "$init" = "runit" ]; then
    mkdir -p "/etc/sv/$svc"
    cp -r "$APP_DIR/services/runit/$svc/"* "/etc/sv/$svc/"
    chmod +x "/etc/sv/$svc/run"
    ln -sf "/etc/sv/$svc" "/etc/service/$svc"
  else
    cp "$APP_DIR/services/sysvinit/$svc.init" "/etc/init.d/$svc"
    chmod +x "/etc/init.d/$svc"
    update-rc.d "$svc" defaults >/dev/null 2>&1 || true
  fi
}

# ---------------------------------------------------------------------------
# Dialog UI
# ---------------------------------------------------------------------------

run_dialog_installer() {
  dialog_init

  local choices
  choices=$(dialog --stdout \
    --title "KioskFrame Installer" \
    --checklist "Select components to install:" \
    "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 10 \
    "photoframe"  "Photo slideshow via DLNA (installs djmount, mpv)"  "on"  \
    "mirror"      "MagicMirror dashboard (installs Node.js)"          "off" \
    "calendar"    "Calendar fetch service"                            "on"  \
    "webui"       "Web UI on port 8080"                               "on"  \
    "kiosk"       "Chromium kiosk shell (installs Xorg)"              "on"  \
    "distrodeck"  "distrodeck package manager TUI"                    "off" \
    "ansible"     "Ansible automation"                                "off" \
    2>&1 >/dev/tty) || {
      reset_tui
      echo "Cancelled." >&2
      exit 0
    }

  reset_tui
  echo "$choices"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

require_root
bootstrap_dialog
load_helpers

SELECTED=$(run_dialog_installer)

install_core

for comp in $SELECTED; do
  case "$comp" in
    photoframe)  install_photoframe ;;
    mirror)      install_mirror ;;
    calendar)    install_calendar ;;
    webui)       install_webui ;;
    kiosk)       install_kiosk ;;
    distrodeck)  install_distrodeck ;;
    ansible)     install_ansible ;;
  esac
done

cat <<EON

Install complete.
Web UI:  http://<host>:8080/
Config:  $CONFIG_DIR/appliance.yaml
Logs:    $LOG_DIR

djmount mounts DLNA servers at paths.dlna_mount in appliance.yaml (/mnt/dlna by default).
EON
