#!/bin/sh
set -euo pipefail

TARGET=${1:-/opt/appliance/magicmirror}

if [ -d "$TARGET" ]; then
  echo "MagicMirror already installed at $TARGET"
  exit 0
fi

mkdir -p "$(dirname "$TARGET")"

git clone https://github.com/MagicMirrorOrg/MagicMirror.git "$TARGET"
cd "$TARGET"

npm install --omit=optional

cat <<'EON'
MagicMirror installed.
Note: On 32-bit antiX, Node.js repo versions may be old.
If npm install fails, consider using an older MagicMirror release or a 32-bit Node build.
EON
