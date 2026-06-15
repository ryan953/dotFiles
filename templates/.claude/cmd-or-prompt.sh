#!/bin/bash
#
# UserPromptSubmit hook: detect raw CLI commands and execute them directly,
# bypassing Claude inference for simple shell operations.
#

set -euo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

[[ -z "$PROMPT" ]] && exit 0

# Trim leading/trailing whitespace
PROMPT="${PROMPT#"${PROMPT%%[![:space:]]*}"}"
PROMPT="${PROMPT%"${PROMPT##*[![:space:]]}"}"

[[ -z "$PROMPT" ]] && exit 0

# Skip multi-line input (likely natural language)
[[ "$PROMPT" == *$'\n'* ]] && exit 0

# Skip slash commands
[[ "$PROMPT" == /* ]] && exit 0

# Skip questions
[[ "$PROMPT" == *\? ]] && exit 0

# Skip prompts with too many words (likely natural language about a command)
WORD_COUNT=$(echo "$PROMPT" | wc -w | tr -d ' ')
[[ "$WORD_COUNT" -gt 12 ]] && exit 0

FIRST_WORD="${PROMPT%% *}"

# Only intercept known CLI commands
case "$FIRST_WORD" in
  # Version control
  git|gh);;
  # File listing / inspection
  ls|cat|head|tail|find|tree|stat|file|wc|pwd);;
  # Search
  grep|rg|ag|fd);;
  # Package managers
  npm|pnpm|yarn|bun|brew|pip|pip3|uv);;
  # Runtimes / build
  node|python|python3|make|docker|kubectl);;
  # Data processing
  jq|yq|sort|uniq|diff);;
  # Network
  curl|wget);;
  # File manipulation
  mkdir|cp|mv|ln|tar|chmod);;
  # System
  which|env|echo|printf);;
  # Custom
  dex|bat|revdiff);;
  *)
    exit 0
    ;;
esac

# Verify the command exists on this system
command -v "$FIRST_WORD" &>/dev/null || exit 0

# Execute the command directly
EXIT_CODE=0
OUTPUT=$(bash -c "$PROMPT" 2>&1) || EXIT_CODE=$?

# Format result with the command echoed back
RESULT="\$ $PROMPT"
[[ -n "$OUTPUT" ]] && RESULT="$RESULT
$OUTPUT"
[[ $EXIT_CODE -ne 0 ]] && RESULT="$RESULT
[exit code: $EXIT_CODE]"

# Block the prompt from going to Claude and show command output
jq -n \
  --arg reason "$RESULT" \
  '{
    "decision": "block",
    "reason": $reason,
    "hookSpecificOutput": {
      "hookEventName": "UserPromptSubmit",
      "suppressOriginalPrompt": true
    }
  }'
