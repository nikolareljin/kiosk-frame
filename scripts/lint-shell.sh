#!/usr/bin/env bash
# Shellcheck every shell script in the tree, found by shebang rather than by
# name, and fail when one is wrong.
#
# Both workflows previously ran:
#   command -v shellcheck && shellcheck $(find . -name '*.sh' ...) || true
# which could not fail twice over. The `|| true` discarded every finding, and
# `-name '*.sh'` never saw a script without the extension -- which is most of
# the ones that matter here: every runit `run`, and the first boot wizard. Of
# the tree's shell scripts it looked at eight and could act on none.
#
# Discovery is by `#!` because that is what makes a file a shell script; the
# extension is a naming habit. Every file this finds is clean today, so the
# gate starts green and any new finding is genuinely new.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v shellcheck >/dev/null 2>&1; then
  # Not a skip. A linter that is absent has checked nothing, and saying so
  # quietly is how the previous version of this passed for months.
  echo "shellcheck is not installed; the shell lint cannot run" >&2
  exit 1
fi

mapfile -t scripts < <(
  find . -path ./.git -prune -o -path ./vendor -prune -o -type f -print \
    | while IFS= read -r f; do
        if head -n1 -- "$f" 2>/dev/null | grep -qE '^#!.*\b(bash|sh)\b'; then
          printf '%s\n' "$f"
        fi
      done | sort
)

if ((${#scripts[@]} == 0)); then
  echo "found no shell scripts, which cannot be right" >&2
  exit 1
fi

echo "shellcheck: ${#scripts[@]} scripts"
shellcheck -x -e SC1091 "${scripts[@]}"
echo "shell lint passed."
