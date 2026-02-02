#!/bin/sh
set -euo pipefail

missing=""

check() {
  if ! command -v "$1" >/dev/null 2>&1; then
    missing="$missing $1"
  fi
}

check mpv
check djmount
check startx
check xset
if ! command -v chromium >/dev/null 2>&1 && ! command -v chromium-browser >/dev/null 2>&1; then
  missing="$missing chromium"
fi
check python3
check pip3
check node
check npm
check ffmpeg
check curl

if [ -n "$missing" ]; then
  echo "Missing dependencies:$missing" >&2
  exit 1
fi

echo "All dependencies found."
