#!/usr/bin/env bash
set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

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
  printf "${RED}Error: Brewfile not found at %s${NC}\n" "$BREWFILE"
  exit 1
fi

print_list() {
  local color="$1"
  local prefix="$2"
  shift 2
  while IFS= read -r item; do
    [ -n "$item" ] && printf "  ${color}${prefix} %s${NC}\n" "$item"
  done <<< "$@"
}

check_drift() {
  local expected="$1"
  local installed="$2"
  local extra missing

  extra=$(comm -13 <(printf "%s\n" "$expected" | sort) <(printf "%s\n" "$installed" | sort))
  missing=$(comm -23 <(printf "%s\n" "$expected" | sort) <(printf "%s\n" "$installed" | sort))

  printf "EXTRA:%s\nMISSING:%s\n" "$extra" "$missing"
}

main() {
  printf "Checking brew drift against: %s\n\n" "$BREWFILE"

  # Parse Brewfile
  local brewfile_brews brewfile_casks brewfile_taps
  brewfile_brews=$(grep '^brew ' "$BREWFILE" | sed 's/brew "\(.*\)"/\1/')
  brewfile_casks=$(grep '^cask ' "$BREWFILE" | sed 's/cask "\(.*\)"/\1/')
  brewfile_taps=$(grep '^tap ' "$BREWFILE" | sed 's/tap "\(.*\)"/\1/')

  # Get installed packages
  local installed_brews installed_casks installed_taps
  installed_brews=$(brew list --formula)
  installed_casks=$(brew list --cask 2>/dev/null || true)
  installed_taps=$(brew tap | grep -v "^homebrew/core$" | grep -v "^homebrew/cask$" || true)

  # Check formulae
  printf "=== Formulae ===\n"
  local drift extra_brews missing_brews
  drift=$(check_drift "$brewfile_brews" "$installed_brews")
  extra_brews=$(grep "^EXTRA:" <<< "$drift" | sed 's/^EXTRA://')
  missing_brews=$(grep "^MISSING:" <<< "$drift" | sed 's/^MISSING://')

  if [ -n "$extra_brews" ]; then
    printf "${YELLOW}Installed but not in Brewfile:${NC}\n"
    print_list "$RED" "•" "$extra_brews"
  fi
  if [ -n "$missing_brews" ]; then
    printf "${YELLOW}In Brewfile but not installed:${NC}\n"
    print_list "$YELLOW" "•" "$missing_brews"
  fi
  if [ -z "$extra_brews" ] && [ -z "$missing_brews" ]; then
    printf "${GREEN}✓ All formulae in sync${NC}\n"
  fi
  printf "\n"

  # Check casks
  printf "=== Casks ===\n"
  local extra_casks missing_casks
  drift=$(check_drift "$brewfile_casks" "$installed_casks")
  extra_casks=$(grep "^EXTRA:" <<< "$drift" | sed 's/^EXTRA://')
  missing_casks=$(grep "^MISSING:" <<< "$drift" | sed 's/^MISSING://')

  if [ -n "$extra_casks" ]; then
    printf "${YELLOW}Installed but not in Brewfile:${NC}\n"
    print_list "$RED" "•" "$extra_casks"
  fi
  if [ -n "$missing_casks" ]; then
    printf "${YELLOW}In Brewfile but not installed:${NC}\n"
    print_list "$YELLOW" "•" "$missing_casks"
  fi
  if [ -z "$extra_casks" ] && [ -z "$missing_casks" ]; then
    printf "${GREEN}✓ All casks in sync${NC}\n"
  fi
  printf "\n"

  # Check taps
  printf "=== Taps ===\n"
  local extra_taps missing_taps
  drift=$(check_drift "$brewfile_taps" "$installed_taps")
  extra_taps=$(grep "^EXTRA:" <<< "$drift" | sed 's/^EXTRA://')
  missing_taps=$(grep "^MISSING:" <<< "$drift" | sed 's/^MISSING://')

  if [ -n "$extra_taps" ]; then
    printf "${YELLOW}Added but not in Brewfile:${NC}\n"
    print_list "$RED" "•" "$extra_taps"
  fi
  if [ -n "$missing_taps" ]; then
    printf "${YELLOW}In Brewfile but not added:${NC}\n"
    print_list "$YELLOW" "•" "$missing_taps"
  fi
  if [ -z "$extra_taps" ] && [ -z "$missing_taps" ]; then
    printf "${GREEN}✓ All taps in sync${NC}\n"
  fi
  printf "\n"

  printf "To sync your system: ${GREEN}brew bundle --file=\"%s\"${NC}\n" "$BREWFILE"
}

main
