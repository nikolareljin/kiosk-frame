#!/usr/bin/env bash
set -euo pipefail

TARGET=${1:-/opt/appliance/magicmirror}

if [ -d "$TARGET" ]; then
  if [ -d "$TARGET/node_modules" ] && [ -f "$TARGET/package.json" ]; then
    echo "MagicMirror already installed at $TARGET"
    exit 0
  fi
  echo "Removing incomplete MagicMirror installation at $TARGET" >&2
  rm -rf "$TARGET"
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required to install MagicMirror." >&2
  exit 2
fi

node_version=$(node -p "process.versions.node")
node_major=${node_version%%.*}
if (( node_major < 18 )); then
  echo "MagicMirror requires Node.js 18 or newer; found $node_version." >&2
  exit 2
fi

# Current MagicMirror releases require Node.js 24 or newer. v2.25.0 supports
# Node.js 18+, which keeps the 32-bit antiX installation path supported.
magicmirror_ref=master
if (( node_major < 24 )); then
  magicmirror_ref=v2.25.0
fi

mkdir -p "$(dirname "$TARGET")"
installed=0
cleanup_failed_install() {
  if (( ! installed )); then
    rm -rf "$TARGET"
  fi
}
trap cleanup_failed_install EXIT

git clone --branch "$magicmirror_ref" --depth 1 https://github.com/MagicMirrorOrg/MagicMirror.git "$TARGET"
cd "$TARGET"
npm install --omit=optional

installed=1
trap - EXIT
printf "MagicMirror installed: %s (Node.js %s).\n" "$magicmirror_ref" "$node_version"
