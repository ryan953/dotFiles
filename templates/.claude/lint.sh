#!/bin/bash
#
# PostToolUse hook script for auto-linting changed files
# Tries linting strategies in order:
# 1. prek (if .venv/bin/prek exists)
# 2. pre-commit (if .pre-commit-config.yaml exists and pre-commit is available)
# 3. eslint/prettier via package.json (using pnpm, yarn, or npm)
#

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract file path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

SKIP_EXTENSIONS='\.md$|\.txt$|\.json$|\.yaml$|\.yml$|\.lock$|\.svg$|\.png$|\.jpg$|\.gif$|\.ico$'

should_skip_file() {
  local f="$1"
  [[ ! -f "$f" ]] && return 0
  echo "$f" | grep -qE "$SKIP_EXTENSIONS" && return 0
  return 1
}

# Build FILE_LIST from explicit path or git state
FILE_LIST=()

if [[ -n "$FILE_PATH" ]]; then
  if should_skip_file "$FILE_PATH"; then
    exit 0
  fi
  FILE_LIST=("$FILE_PATH")
else
  # No file provided — discover from git state
  RAW_FILES=()

  # 1. Staged files
  while IFS= read -r f; do
    [[ -n "$f" ]] && RAW_FILES+=("$f")
  done < <(git diff --cached --name-only --diff-filter=d 2>/dev/null)

  # 2. Unstaged modified files (fallback)
  if [[ ${#RAW_FILES[@]} -eq 0 ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && RAW_FILES+=("$f")
    done < <(git diff --name-only --diff-filter=d 2>/dev/null)
  fi

  # 3. Most recent commit (fallback)
  if [[ ${#RAW_FILES[@]} -eq 0 ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && RAW_FILES+=("$f")
    done < <(git diff --name-only --diff-filter=d HEAD~1 HEAD 2>/dev/null)
  fi

  for f in "${RAW_FILES[@]}"; do
    should_skip_file "$f" || FILE_LIST+=("$f")
  done

  if [[ ${#FILE_LIST[@]} -eq 0 ]]; then
    exit 0
  fi
fi

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

# Check if prek is available
has_prek() {
  local project_root="$1"

  for venv in "$project_root/.venv" "$project_root/venv" "$project_root/.virtualenv"; do
    if [[ -x "$venv/bin/prek" ]]; then
      return 0
    fi
  done

  command -v prek &>/dev/null && return 0

  return 1
}

# Get prek command
get_prek_cmd() {
  local project_root="$1"

  for venv in "$project_root/.venv" "$project_root/venv" "$project_root/.virtualenv"; do
    if [[ -x "$venv/bin/prek" ]]; then
      echo "$venv/bin/prek"
      return 0
    fi
  done

  if command -v prek &>/dev/null; then
    echo "prek"
    return 0
  fi

  return 1
}

# Run prek on file(s) — pass all remaining args as file paths
run_prek() {
  local project_root="$1"
  shift
  local prek_cmd

  prek_cmd=$(get_prek_cmd "$project_root") || return 1

  local rel_paths=()
  for f in "$@"; do
    rel_paths+=("$(get_relative_path "$project_root" "$f")")
  done

  cd "$project_root"

  local files_arg
  files_arg=$(IFS=,; echo "${rel_paths[*]}")

  if $prek_cmd run --files "$files_arg" 2>&1; then
    return 0
  else
    return 1
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

# Run pre-commit on file(s)
run_precommit() {
  local project_root="$1"
  shift
  local precommit_cmd

  precommit_cmd=$(get_precommit_cmd "$project_root") || return 1

  local rel_paths=()
  for f in "$@"; do
    rel_paths+=("$(get_relative_path "$project_root" "$f")")
  done

  cd "$project_root"

  # pre-commit --files accepts multiple paths
  $precommit_cmd run --files "${rel_paths[@]}" 2>&1 || true
  return 0
}

# Run JS linters (eslint/prettier) on file(s)
run_js_linters() {
  local project_root="$1"
  local pm="$2"
  shift 2
  local pkg="$project_root/package.json"

  local rel_paths=()
  for f in "$@"; do
    rel_paths+=("$(get_relative_path "$project_root" "$f")")
  done

  cd "$project_root"

  local ran_something=false

  if jq -e '.scripts["lint:fix"]' "$pkg" &>/dev/null; then
    $pm run lint:fix -- "${rel_paths[@]}" 2>&1 || true
    ran_something=true
  elif jq -e '.scripts.lint' "$pkg" &>/dev/null; then
    $pm run lint -- --fix "${rel_paths[@]}" 2>&1 || true
    ran_something=true
  fi

  if jq -e '.scripts.format' "$pkg" &>/dev/null; then
    $pm run format -- "${rel_paths[@]}" 2>&1 || true
    ran_something=true
  fi

  if [[ "$ran_something" == "false" ]]; then
    if jq -e '.devDependencies.eslint // .dependencies.eslint' "$pkg" &>/dev/null; then
      $pm exec eslint --fix "${rel_paths[@]}" 2>&1 || true
      ran_something=true
    fi

    if jq -e '.devDependencies.prettier // .dependencies.prettier' "$pkg" &>/dev/null; then
      $pm exec prettier --write "${rel_paths[@]}" 2>&1 || true
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
  local first_file="${FILE_LIST[0]}"
  local project_root
  project_root=$(find_project_root "$(dirname "$first_file")") || exit 0

  # Strategy 1: Try prek
  if has_prek "$project_root"; then
    run_prek "$project_root" "${FILE_LIST[@]}"
    exit 0
  fi

  # Strategy 2: Try pre-commit
  if has_precommit "$project_root"; then
    run_precommit "$project_root" "${FILE_LIST[@]}"
    exit 0
  fi

  # Strategy 3: Try JS linters (eslint/prettier)
  if has_js_linters "$project_root"; then
    local pm
    pm=$(detect_package_manager "$project_root")
    run_js_linters "$project_root" "$pm" "${FILE_LIST[@]}"
    exit 0
  fi

  exit 0
}

main
