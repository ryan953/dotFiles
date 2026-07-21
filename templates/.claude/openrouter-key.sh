#!/usr/bin/env zsh

# apiKeyHelper: print the OpenRouter key that .zprofile already exports.
# Sourcing keeps .zprofile the single source of truth; its stdout/stderr are
# discarded so only the key reaches Claude Code.
source "${HOME}/.zprofile" >/dev/null 2>&1
print -r -- "${OPENROUTER_API_KEY}"
