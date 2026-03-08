#!/bin/bash
#
# PostToolUse hook script for auto-linting changed files
# Tries linting strategies in order:
# 1. pre-commit (if .pre-commit-config.yaml exists and pre-commit is available)
# 2. eslint/prettier via package.json (using pnpm, yarn, or npm)
#

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract file path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Skip non-existent files (might have been deleted)
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Skip certain file types that don't need linting
case "$FILE_PATH" in
  *.md|*.txt|*.json|*.yaml|*.yml|*.lock|*.svg|*.png|*.jpg|*.gif|*.ico)
    exit 0
    ;;
esac

# Find project root by walking up directories
find_project_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    # Check for common project root indicators
    if [[ -f "$dir/package.json" ]] || \
       [[ -f "$dir/pyproject.toml" ]] || \
       [[ -f "$dir/.pre-commit-config.yaml" ]] || \
       [[ -d "$dir/.git" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Detect package manager from project
detect_package_manager() {
  local project_root="$1"
  
  # Check packageManager field in package.json first
  if [[ -f "$project_root/package.json" ]]; then
    local pm=$(jq -r '.packageManager // empty' "$project_root/package.json" 2>/dev/null | cut -d'@' -f1)
    if [[ -n "$pm" ]]; then
      echo "$pm"
      return 0
    fi
  fi
  
  # Check for lockfiles
  if [[ -f "$project_root/pnpm-lock.yaml" ]]; then
    echo "pnpm"
  elif [[ -f "$project_root/yarn.lock" ]]; then
    echo "yarn"
  elif [[ -f "$project_root/package-lock.json" ]]; then
    echo "npm"
  elif [[ -f "$project_root/bun.lockb" ]]; then
    echo "bun"
  else
    echo "npm"
  fi
}

# Check if pre-commit is available
has_precommit() {
  local project_root="$1"
  
  # Must have config file
  [[ -f "$project_root/.pre-commit-config.yaml" ]] || return 1
  
  # Check if pre-commit is available (in PATH or venv)
  if command -v pre-commit &>/dev/null; then
    return 0
  fi
  
  # Check common venv locations
  for venv in "$project_root/.venv" "$project_root/venv" "$project_root/.virtualenv"; do
    if [[ -x "$venv/bin/pre-commit" ]]; then
      return 0
    fi
  done
  
  return 1
}

# Get pre-commit command
get_precommit_cmd() {
  local project_root="$1"
  
  if command -v pre-commit &>/dev/null; then
    echo "pre-commit"
    return 0
  fi
  
  for venv in "$project_root/.venv" "$project_root/venv" "$project_root/.virtualenv"; do
    if [[ -x "$venv/bin/pre-commit" ]]; then
      echo "$venv/bin/pre-commit"
      return 0
    fi
  done
  
  return 1
}

# Check if package.json has eslint or prettier
has_js_linters() {
  local project_root="$1"
  local pkg="$project_root/package.json"
  
  [[ -f "$pkg" ]] || return 1
  
  # Check for eslint or prettier in devDependencies or dependencies
  if jq -e '.devDependencies.eslint // .dependencies.eslint // .devDependencies.prettier // .dependencies.prettier' "$pkg" &>/dev/null; then
    return 0
  fi
  
  # Check for eslint/prettier scripts
  if jq -e '.scripts.lint // .scripts.format // .scripts["lint:fix"]' "$pkg" &>/dev/null; then
    return 0
  fi
  
  return 1
}

# Get relative path from project root
get_relative_path() {
  local project_root="$1"
  local file_path="$2"
  
  # Use realpath to resolve any symlinks and get canonical paths
  local real_root=$(realpath "$project_root")
  local real_file=$(realpath "$file_path")
  
  # Remove project root prefix to get relative path
  echo "${real_file#$real_root/}"
}

# Run pre-commit on the file
run_precommit() {
  local project_root="$1"
  local file_path="$2"
  local precommit_cmd
  
  precommit_cmd=$(get_precommit_cmd "$project_root") || return 1
  
  local relative_path
  relative_path=$(get_relative_path "$project_root" "$file_path")
  
  cd "$project_root"
  
  # Run pre-commit on specific file
  # Use --files to target specific file, allow failures (lint errors shouldn't block)
  if $precommit_cmd run --files "$relative_path" 2>&1; then
    return 0
  else
    # Pre-commit returns non-zero if it made changes or found issues
    # This is expected behavior, not an error
    return 0
  fi
}

# Run JS linters (eslint/prettier) on the file
run_js_linters() {
  local project_root="$1"
  local file_path="$2"
  local pm="$3"
  local pkg="$project_root/package.json"
  
  local relative_path
  relative_path=$(get_relative_path "$project_root" "$file_path")
  
  cd "$project_root"
  
  local ran_something=false
  
  # Check for lint:fix or lint script
  if jq -e '.scripts["lint:fix"]' "$pkg" &>/dev/null; then
    $pm run lint:fix -- "$relative_path" 2>&1 || true
    ran_something=true
  elif jq -e '.scripts.lint' "$pkg" &>/dev/null; then
    # Try with --fix flag for eslint-based lint scripts
    $pm run lint -- --fix "$relative_path" 2>&1 || true
    ran_something=true
  fi
  
  # Check for format script (usually prettier)
  if jq -e '.scripts.format' "$pkg" &>/dev/null; then
    $pm run format -- "$relative_path" 2>&1 || true
    ran_something=true
  fi
  
  # If no scripts, try running eslint/prettier directly if installed
  if [[ "$ran_something" == "false" ]]; then
    # Check if eslint is available
    if jq -e '.devDependencies.eslint // .dependencies.eslint' "$pkg" &>/dev/null; then
      $pm exec eslint --fix "$relative_path" 2>&1 || true
      ran_something=true
    fi
    
    # Check if prettier is available
    if jq -e '.devDependencies.prettier // .dependencies.prettier' "$pkg" &>/dev/null; then
      $pm exec prettier --write "$relative_path" 2>&1 || true
      ran_something=true
    fi
  fi
  
  if [[ "$ran_something" == "true" ]]; then
    return 0
  fi
  
  return 1
}

# Main execution
main() {
  local project_root
  project_root=$(find_project_root "$(dirname "$FILE_PATH")") || exit 0
  
  # Strategy 1: Try pre-commit
  if has_precommit "$project_root"; then
    run_precommit "$project_root" "$FILE_PATH"
    exit 0
  fi
  
  # Strategy 2: Try JS linters (eslint/prettier)
  if has_js_linters "$project_root"; then
    local pm
    pm=$(detect_package_manager "$project_root")
    run_js_linters "$project_root" "$FILE_PATH" "$pm"
    exit 0
  fi
  
  # No linting strategy found, exit silently
  exit 0
}

main
