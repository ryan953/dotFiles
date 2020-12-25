#!/usr/bin/env zsh
set -e

cd "$(dirname "$0")"

backup_file () {
  local file="$1"
  # regular file and not a symlink
  # https://tldp.org/LDP/abs/html/fto.html
  if [ -f "$file" ] && [ ! -h "$file" ]; then
    mv "$file" $file.bak
    echo "   --- Backed up: $file"
  fi
}

link_file () {
  local source="$1"
  local dest="$2"
  mkdir -p $(dirname "$dest")
  ln -sf "$source" "$dest"
  echo "   --- Linked: $source to $dest"
}

copy_file () {
  local source="$1"
  local dest="$2"
  mkdir -p $(dirname "$dest")
  cp -f "$source" "$dest"
  echo "   --- Copied: $source to $dest"
}

ensure_repo () {
  local name="$1"
  local repo="$2"
  local dest="$3"
  if [ -d "$dest" ]; then
    echo "###### Updating $name"
    git -C "$dest" pull
  else
    echo "###### Cloning $name"
    git clone --depth 1 "$repo" "$dest"
  fi
}

ensure_brew () {
  local name=$1

  brew upgrade $name || brew install $name
}

ensure_font () {
  local release=$1
  local name=$2

  wget \
    --output-document /tmp/${name}.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/download/${release}/${name}.zip
  unzip -o /tmp/${name}.zip -d ~/.local/share/fonts
}

check_file_exists () {
  file=$1
  message=$2

  if [[ -f "$file" ]]; then
    out="\033[1;32m✔\033[0m"
  else
    out="\033[1;31m✘\033[0m"
  fi

  printf " $out $message\n"
}

init () {
  OS="$(uname)"
  case $OS in
    Darwin)
      echo "##### Install Apple Command Line Tools"
      xcode-select --install || true

      echo "###### Installing OSX Dependencies"
      ensure_brew ripgrep
      ensure_brew the_silver_searcher
      ensure_brew tmux
      ensure_brew vim
      ensure_brew universal-ctags/universal-ctags/universal-ctags || brew install --HEAD universal-ctags/universal-ctags/universal-ctags

      # Keep homebrew up to date
      brew upgrade terminal-notifier || brew install terminal-notifier
      brew tap domt4/autoupdate
      brew autoupdate --start --enable-notification || true

      # NerdFonts
      brew tap homebrew/cask-fonts
      brew install --cask font-meslo-lg-nerd-font || true

      # UI Programs
      brew install --cask alacritty || true
      brew install --cask bitwarden || true
      brew install --cask google-chrome || true
      brew install --cask slack || true

      # OSX Settings
      ./install-osx.sh
    ;;
    Linux)
      echo "###### Installing Linux Dependencies"
      if [ "`id -u`" = "0" ]; then
        Sudo=''
      elif which sudo; then
        Sudo='sudo'
      fi

      if dpkg --compare-versions $(lsb_release -sr) 'le' '18.04' ; then
        (cd /tmp && curl -LO https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb)
        $Sudo dpkg -i /tmp/ripgrep_12.1.1_amd64.deb
      fi

      $Sudo apt-get install -y \
        ripgrep \
        silversearcher-ag \
        tmux \
        unzip \
        vim

      # NerdFonts
      echo "### Download fonts"
      # ensure_font "v2.1.0" "Meslo"
      if which fc-cache > /dev/null; then
        fc-cache -fv
      fi
    ;;
  esac

  echo "###### Linking templates/ to $HOME"
  for source in $(find $(pwd)/templates -type f | sort -nr); do
    dest="${source//$(pwd)\/templates/$HOME}"
    backup_file "$dest"
    link_file "$source" "$dest"
  done

  rm -f "$HOME"/.tmux/version_* || true
  copy_file "$(pwd)/templates/.tmux/version_1.9_down.conf" "$HOME/.tmux/version_1.9_down.conf"
  copy_file "$(pwd)/templates/.tmux/version_1.9_to_2.1.conf" "$HOME/.tmux/version_1.9_to_2.1.conf"
  copy_file "$(pwd)/templates/.tmux/version_2.1_up.conf" "$HOME/.tmux/version_2.1_up.conf"

  echo "###### OS Specific Change to templates"
  case $OS in
    Darwin)
      echo 'Include ./config.darwin' >> ~/.ssh/config
      echo 'Include ./config.local' >> ~/.ssh/config
    ;;
    Linux)
      echo 'Include ./config.linux' >> ~/.ssh/config
      echo 'Include ./config.local' >> ~/.ssh/config
    ;;
  esac

  # Install or update fzf
  ensure_repo "fzf" https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --key-bindings --completion --no-update-rc

  ensure_repo "Tmux Theme (clone)" https://github.com/ryan953/tmux-onedark-theme.git ~/.tmux/tmux-onedark-theme
  ensure_repo "Tmux Sensible" https://github.com/tmux-plugins/tmux-sensible ~/.tmux/tmux-sensible
  ensure_repo "Tmux Prefix Highlight" https://github.com/tmux-plugins/tmux-prefix-highlight.git ~/.tmux/tmux-prefix-highlight
  ensure_repo "Tmux fzf" https://github.com/sainnhe/tmux-fzf ~/.tmux/tmux-fzf

  # Install or update vundle (depends on vim)
  ensure_repo "Vundle" https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  vim +PluginInstall +qall

  # File dependency for `z` antigen plugin (see .antigenrc)
  touch ~/.z

  # Allow zsh, then change the default
  case $OS in
    Darwin)
      if [[ $(dscl . -read ~/ UserShell | sed 's/UserShell: //') == $(which zsh) ]]; then
        echo "Shell set to $(which zsh)"
      else
        sudo sh -c "echo $(which zsh) >> /etc/shells"
        chsh -s $(which zsh)
      fi
    ;;
    Linux)
    ;;
  esac
  echo "###### Done"

  echo ""
  echo "You can extend this setup by editing these files:"
  check_file_exists "$HOME/.zprofile" "~/.zprofile then start a new zsh session"
  check_file_exists "$HOME/.gitconfig.local" "~/.gitconfig.local"
  check_file_exists "$HOME/.ssh/config.local" "~/.ssh/config.local"

  echo ""
  # https://github.com/romkatv/powerlevel10k/blob/master/README.md#weird-things-happen-after-typing-source-zshrc
  echo "Start a new zsh session to load changes. (new tab, or run $(which zsh))"
}

init
