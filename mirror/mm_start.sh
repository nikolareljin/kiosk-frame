#!/bin/sh
set -euo pipefail

MM_PATH=${1:-/opt/appliance/magicmirror}
CONFIG_PATH=${2:-/opt/appliance/magicmirror/config/config.js}

cd "$MM_PATH"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Missing MagicMirror config at $CONFIG_PATH" >&2
  exit 1
fi

export NODE_ENV=production
node serveronly --config "$CONFIG_PATH"
