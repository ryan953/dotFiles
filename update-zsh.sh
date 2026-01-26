#!/usr/bin/env zsh

# Helper function to run command if it exists
run_if_command_exists() {
  local cmd=$1
  local description=$2
  shift 2

  if command -v "$cmd" &>/dev/null; then
    echo "Updating $description..."
    "$@"
  else
    echo "$description not found, skipping..."
  fi
}

# Helper function to run commands in a directory if it exists
run_in_dir_if_exists() {
  local dir=$1
  local description=$2
  shift 2

  if [ -d "$dir" ]; then
    echo "Updating $description..."
    (cd "$dir" && "$@")
  else
    echo "$description directory not found, skipping..."
  fi
}

# Helper function to update git repos
update_git_repo() {
  local dir=$1
  local description=$2

  if [ -d "$dir" ]; then
    (cd "$dir" && git pull)
  fi
}

# Update FZF
run_in_dir_if_exists ~/.fzf "FZF" git pull && ./install --all --xdg

# Update Zsh
run_in_dir_if_exists ~/.zsh "Zsh" git pull && ./install

# Update Tmux Plugins
if [ -d ~/.tmux ]; then
  echo "Updating Tmux plugins..."
  update_git_repo ~/.tmux/tmux-onedark-theme "tmux-onedark-theme"
  update_git_repo ~/.tmux/tmux-sensible "tmux-sensible"
  update_git_repo ~/.tmux/tmux-prefix-highlight "tmux-prefix-highlight"
  update_git_repo ~/.tmux/tmux-fzf "tmux-fzf"
else
  echo "Tmux directory not found, skipping..."
fi

# Update Vim Plugins
run_if_command_exists vim "Vim plugins" vim +PluginUpdate +qall

# Update Homebrew
run_if_command_exists brew "Homebrew" brew update && brew upgrade

echo ""
echo "Don't forget to update zinit & its plugins..."
echo "Run: zinit self-update && zinit update --all"
