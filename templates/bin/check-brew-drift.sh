#!/usr/bin/env bash
set -euo pipefail

# Colors
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly DIM=$'\033[2m'
readonly NC=$'\033[0m'

# Resolve symlinks to get the real script location
resolve_symlink() {
  local source="$1"
  while [ -L "$source" ]; do
    local dir
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source"
  done
  echo "$source"
}

# Find dotfiles root (go up two dirs from bin/)
SCRIPT_PATH="$(resolve_symlink "${BASH_SOURCE[0]}")"
readonly DOTFILES_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)"
readonly BREWFILE="${DOTFILES_ROOT}/Brewfile"

if [ ! -f "$BREWFILE" ]; then
  printf '%sError: Brewfile not found at %s%s\n' "$RED" "$BREWFILE" "$NC"
  exit 1
fi

print_list() {
  local color="$1"
  local prefix="$2"
  shift 2
  while IFS= read -r item; do
    [ -n "$item" ] && printf '  %s%s %s%s\n' "$color" "$prefix" "$item" "$NC"
  done <<< "$@"
}

sorted() {
  printf "%s\n" "$1" | grep -v '^$' | sort -u
}

# comm wrapper that tolerates empty inputs
diff_extra() {
  comm -13 <(sorted "$1") <(sorted "$2") | grep -v '^$' || true
}

diff_missing() {
  comm -23 <(sorted "$1") <(sorted "$2") | grep -v '^$' || true
}

# "user/tap/formula" -> "formula"
strip_tap_prefix() {
  local name
  while IFS= read -r name; do
    [ -n "$name" ] && echo "${name##*/}"
  done
}

main() {
  printf "Checking brew drift against: %s\n" "$BREWFILE"
  printf '%sCollecting installed packages and resolving dependencies...%s\n\n' "$DIM" "$NC"

  # --- Gather all data upfront ---

  local brewfile_brews_raw brewfile_casks brewfile_taps
  brewfile_brews_raw=$(grep '^brew ' "$BREWFILE" | sed 's/brew "\(.*\)"/\1/' || true)
  brewfile_casks=$(grep '^cask ' "$BREWFILE" | sed 's/cask "\(.*\)"/\1/' || true)
  brewfile_taps=$(grep '^tap ' "$BREWFILE" | sed 's/tap "\(.*\)"/\1/' || true)

  # Normalize tap-prefixed names for comparison with `brew list` output
  local brewfile_brews
  brewfile_brews=$(echo "$brewfile_brews_raw" | strip_tap_prefix)

  local installed_brews installed_casks installed_taps
  installed_brews=$(brew list --formula)
  installed_casks=$(brew list --cask 2>/dev/null || true)
  installed_taps=$(brew tap | grep -v "^homebrew/core$" | grep -v "^homebrew/cask$" || true)

  # Resolve transitive deps of every Brewfile formula so that packages like
  # autoconf (pulled in by pyenv) aren't flagged as extra.
  local brewfile_deps=""
  if [ -n "$brewfile_brews_raw" ]; then
    # shellcheck disable=SC2046
    brewfile_deps=$(brew deps --union $(echo "$brewfile_brews_raw" | tr '\n' ' ') 2>/dev/null || true)
  fi

  # Expected formulae = Brewfile entries + their transitive deps
  local expected_brews
  expected_brews=$(printf "%s\n%s" "$brewfile_brews" "$brewfile_deps")

  # --- Compute all diffs before printing anything ---

  local extra_brews missing_brews
  extra_brews=$(diff_extra "$expected_brews" "$installed_brews")
  missing_brews=$(diff_missing "$brewfile_brews" "$installed_brews")

  local extra_casks missing_casks
  extra_casks=$(diff_extra "$brewfile_casks" "$installed_casks")
  missing_casks=$(diff_missing "$brewfile_casks" "$installed_casks")

  local extra_taps missing_taps
  extra_taps=$(diff_extra "$brewfile_taps" "$installed_taps")
  missing_taps=$(diff_missing "$brewfile_taps" "$installed_taps")

  # --- Display results ---

  printf "=== Formulae ===\n"
  if [ -n "$extra_brews" ]; then
    printf '%sInstalled but not in Brewfile (and not a dependency):%s\n' "$YELLOW" "$NC"
    print_list "$RED" "•" "$extra_brews"
  fi
  if [ -n "$missing_brews" ]; then
    printf '%sIn Brewfile but not installed:%s\n' "$YELLOW" "$NC"
    print_list "$YELLOW" "•" "$missing_brews"
  fi
  if [ -z "$extra_brews" ] && [ -z "$missing_brews" ]; then
    printf '%s✓ All formulae in sync%s\n' "$GREEN" "$NC"
  fi
  printf "\n"

  printf "=== Casks ===\n"
  if [ -n "$extra_casks" ]; then
    printf '%sInstalled but not in Brewfile:%s\n' "$YELLOW" "$NC"
    print_list "$RED" "•" "$extra_casks"
  fi
  if [ -n "$missing_casks" ]; then
    printf '%sIn Brewfile but not installed:%s\n' "$YELLOW" "$NC"
    print_list "$YELLOW" "•" "$missing_casks"
  fi
  if [ -z "$extra_casks" ] && [ -z "$missing_casks" ]; then
    printf '%s✓ All casks in sync%s\n' "$GREEN" "$NC"
  fi
  printf "\n"

  printf "=== Taps ===\n"
  if [ -n "$extra_taps" ]; then
    printf '%sAdded but not in Brewfile:%s\n' "$YELLOW" "$NC"
    print_list "$RED" "•" "$extra_taps"
  fi
  if [ -n "$missing_taps" ]; then
    printf '%sIn Brewfile but not added:%s\n' "$YELLOW" "$NC"
    print_list "$YELLOW" "•" "$missing_taps"
  fi
  if [ -z "$extra_taps" ] && [ -z "$missing_taps" ]; then
    printf '%s✓ All taps in sync%s\n' "$GREEN" "$NC"
  fi
  printf "\n"

  # --- Summary counts ---
  local n_extra=0 n_missing=0
  [ -n "$extra_brews" ]  && n_extra=$((n_extra  + $(wc -l <<< "$extra_brews")))
  [ -n "$extra_casks" ]  && n_extra=$((n_extra  + $(wc -l <<< "$extra_casks")))
  [ -n "$extra_taps" ]   && n_extra=$((n_extra  + $(wc -l <<< "$extra_taps")))
  [ -n "$missing_brews" ] && n_missing=$((n_missing + $(wc -l <<< "$missing_brews")))
  [ -n "$missing_casks" ] && n_missing=$((n_missing + $(wc -l <<< "$missing_casks")))
  [ -n "$missing_taps" ]  && n_missing=$((n_missing + $(wc -l <<< "$missing_taps")))

  if [ "$n_extra" -eq 0 ] && [ "$n_missing" -eq 0 ]; then
    printf '%sEverything is in sync!%s\n' "$GREEN" "$NC"
  else
    printf "=== Summary: %s extra, %s missing ===\n" "$n_extra" "$n_missing"
    printf 'To sync your system: %sbrew bundle --file="%s"%s\n' "$GREEN" "$BREWFILE" "$NC"
  fi
}

main
