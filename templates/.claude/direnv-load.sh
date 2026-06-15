#!/bin/bash

set -euo pipefail

# Writes direnv setup to CLAUDE_ENV_FILE, which is sourced before each Bash command.
# Also wraps cd so mid-command directory changes re-evaluate direnv.

if [ -n "$CLAUDE_ENV_FILE" ]; then
  cat >> "$CLAUDE_ENV_FILE" <<'DIRENV'
eval "$(direnv export bash)"
cd() {
  builtin cd "$@" && eval "$(direnv export bash)"
}
DIRENV
fi
exit 0
