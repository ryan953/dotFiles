#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

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
  brew upgrade ${1} ${2:-} || brew install ${1} ${2:-}
}

ensure_font () {
  local release=$1
  local name=$2

  wget \
    --output-document /tmp/${name}.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/download/${release}/${name}.zip
  unzip -o /tmp/${name}.zip -d ~/.local/share/fonts
}

sudo_cmd () {
  if [ "`id -u`" = "0" ]; then
    echo ''
  elif command -v sudo; then
    echo 'sudo'
  fi
}

install_dpkg () {
  local url="${1}"
  local filename=$(basename ${url})
  local Sudo=$(sudo_cmd)

  (cd /tmp && curl -LO "${url}")
  $Sudo dpkg -i "/tmp/${filename}"
}

file_exists_indicator () {
  file="${1:-}"

  if [[ -f "$file" ]]; then
    printf "\033[1;32m✔\033[0m"
  else
    printf "\033[1;31m✘\033[0m"
  fi
}

init () {
  OS="$(uname)"
  case $OS in
    Darwin)
      arch_name="$(uname -m)"
      if [ "${arch_name}" = "x86_64" ]; then
        if [ "$(sysctl -in sysctl.proc_translated)" = "1" ]; then
          echo "ERROR: Running on Rosetta 2"
          echo ""
          echo "Re-run this as:"
          echo "   arch -arm64 $0"
          echo ""
          exit 1
        else
          echo "Running on native Intel"
        fi
      elif [ "${arch_name}" = "arm64" ]; then
        echo "Running on ARM"
      else
        echo "Unknown architecture: ${arch_name}"
      fi

      echo "##### Install Apple Command Line Tools"
      xcode-select --install || true

      if [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      echo "###### Installing OSX Dependencies"
      ensure_brew bat
      ensure_brew exa
      ensure_brew fd
      ensure_brew git
      ensure_brew git-delta
      ensure_brew htop
      ensure_brew jq
      ensure_brew ripgrep
      ensure_brew the_silver_searcher
      ensure_brew tmux
      ensure_brew vim

      # Keep homebrew up to date
      ensure_brew terminal-notifier
      brew tap domt4/autoupdate
      brew autoupdate --start --enable-notification || true

      # NerdFonts
      brew tap homebrew/cask-fonts
      brew tap homebrew/cask-drivers
      ensure_brew --cask font-meslo-lg-nerd-font

      # UI Programs
      ensure_brew --cask alacritty || true
      ensure_brew --cask bitwarden || true
      ensure_brew --cask google-chrome || true
      ensure_brew --cask slack || true
      ensure_brew --cask spotify || true
      ensure_brew --cask sonos || true
      # OSX Settings
      ./install-osx.sh
    ;;
    Linux)
      echo "###### Installing Linux Dependencies"
      local Sudo=$(sudo_cmd)

      install_dpkg https://github.com/sharkdp/bat/releases/download/v0.17.1/bat_0.17.1_amd64.deb

      # libgcc-s1 >= 4.2 is needed for delta on 18.04
      $Sudo apt-get install -y libgcc-s1
      install_dpkg https://github.com/dandavison/delta/releases/download/0.5.0/git-delta_0.5.0_amd64.deb 

      install_dpkg https://github.com/sharkdp/fd/releases/download/v8.2.1/fd_8.2.1_amd64.deb

      install_dpkg https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb

      $Sudo apt-get install -y \
        bat \
        fd \
        git \
        htop \
        jq \
        ripgrep \
        silversearcher-ag \
        unzip \
        vim

      if dpkg --compare-versions $(lsb_release -sr) 'le' '18.04' ; then
        filename=tmux-3.0a-x86_64.AppImage
        if [ -f $filename ]; then
          (
            cd ~/bin \
            && curl -LO https://github.com/nelsonenzo/tmux-appimage/releases/download/3.0a-appimage0.2.0/tmux-3.0a-x86_64.AppImage
          )
        fi
        ln -sf ~/bin/$filename ~/bin/tmux
      else
        $Sudo apt-get install -y tmux
      fi

      (
        cd /tmp \
        && curl -LO https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip \
        && unzip -o exa-linux-x86_64-0.9.0.zip -d ~/bin
      )
      ln -sf ~/bin/exa-linux-x86_64 ~/bin/exa

      # NerdFonts
      echo "### Download fonts"
      # ensure_font "v2.1.0" "Meslo"
      if command -v fc-cache > /dev/null; then
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

  # Files which must be copied, not symlinked
  rm -f "$HOME"/.tmux/version_* || true
  copy_file "$(pwd)/templates/.tmux/version_1.9_down.conf" "$HOME/.tmux/version_1.9_down.conf"
  copy_file "$(pwd)/templates/.tmux/version_1.9_to_2.1.conf" "$HOME/.tmux/version_1.9_to_2.1.conf"
  copy_file "$(pwd)/templates/.tmux/version_2.1_up.conf" "$HOME/.tmux/version_2.1_up.conf"
  copy_file "$(pwd)/templates/.tmux/version_2.3_up.conf" "$HOME/.tmux/version_2.3_up.conf"

  echo "###### Generating config files"
  for source in $(find $(pwd)/generators -type f | sort -nr); do
    dest="${source//$(pwd)\/generators/$HOME}"
    backup_file "$dest"
    eval "$source" > "$dest"
    echo "   --- Generated: $dest"
  done

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
      zsh_path=$(command -v zsh)
      if [[ $(dscl . -read ~/ UserShell | sed 's/UserShell: //') == $zsh_path ]]; then
        echo "Shell set to $zsh_path"
      else
        sudo sh -c "echo $zsh_path >> /etc/shells"
        chsh -s $zsh_path
      fi
    ;;
    Linux)
    ;;
  esac
  echo "###### Done"

  echo ""
  echo "You can extend this setup by editing these files:"
  echo " $(file_exists_indicator "$HOME/.zprofile") ~/.zprofile then start a new zsh session"
  echo " $(file_exists_indicator "$HOME/.gitconfig.local") ~/.gitconfig.local"
  echo " $(file_exists_indicator "$HOME/.ssh/config.local") ~/.ssh/config.local"

  echo ""
  # https://github.com/romkatv/powerlevel10k/blob/master/README.md#weird-things-happen-after-typing-source-zshrc
  echo "Start a new zsh session to load changes. (new tab, or run $(command -v zsh))"
}

init
