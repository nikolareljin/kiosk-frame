#!/bin/sh
set -euo pipefail

HOST=${1:-8.8.8.8}
TRIES=${2:-30}
SLEEP=${3:-2}

while [ "$TRIES" -gt 0 ]; do
  if ping -c 1 -W 1 "$HOST" >/dev/null 2>&1; then
    exit 0
  fi
  TRIES=$((TRIES-1))
  sleep "$SLEEP"
done
exit 1
