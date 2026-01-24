#!/bin/bash
# Notify script for Claude Code hooks
# Usage: notify.sh "Title" "Message"
# Reads JSON input from stdin and includes cwd in message

TITLE="$1"
MESSAGE="$2"

# Read stdin (Claude hook input)
INPUT=$(cat)

# Try to extract cwd from JSON input if jq is available
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
fi

# If no cwd from input, use current directory
if [ -z "$CWD" ]; then
  CWD=$(pwd)
fi

# Shorten home directory to ~
CWD="${CWD/#$HOME/~}"

# Append cwd to message
FULL_MESSAGE="📁 $CWD"$'\n'"$MESSAGE"

# Send notification
if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier -title "$TITLE" -message "$FULL_MESSAGE" -sound default
fi
