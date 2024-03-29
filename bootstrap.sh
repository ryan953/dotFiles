#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############
# Can run with:
# `BRANCH=master && BRANCH=${BRANCH} sh -c "$(wget -O- https://raw.githubusercontent.com/ryan953/dotFiles/${BRANCH}/bootstrap.sh)"`
# or
# `BRANCH=master && BRANCH=${BRANCH} sh -c "$(curl https://raw.githubusercontent.com/ryan953/dotFiles/${BRANCH}/bootstrap.sh)"`
###############

cd "$(dirname "$0")"

check_dist () {
  (. /etc/os-release; echo $ID)
}

check_version () {
  (. /etc/os-release; echo $VERSION_ID)
}

install_osx_dependencies () {
  if which brew > /dev/null; then
    echo "######## Found homebrew"
    if $(git rev-parse --is-shallow-repository); then
      echo "########## Making repo's unshallow (this may take a while)..."
      git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
      git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask fetch --unshallow
    fi
    echo "######## Updating homebrew..."
    brew update
  else
    echo "######## Installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -f /usr/local/bin/brew ]]; then
    brew_prefix='/usr/local'
  fi
  if [[ -f /opt/homebrew/bin/brew ]]; then
    brew_prefix='/opt/homebrew'
  fi
  ${brew_prefix}/bin/brew list git > /dev/null || ${brew_prefix}/bin/brew install git
  ${brew_prefix}/bin/brew list zsh > /dev/null || ${brew_prefix}/bin/brew install zsh
}

install_linux_dependencies () {
  DIST="$(check_dist)"
  VERSION="$(check_version)"
  echo "###### Installing dependencies for $DIST $VERSION"

  if [ "`id -u`" = "0" ]; then
    Sudo=''
  elif which sudo; then
    Sudo='sudo'
  else
    echo "WARNING: 'sudo' command not found. Skipping the installation of dependencies. "
    echo "If this script fails, you need to do one of these options:"
    echo "   1) Install 'sudo' so dependencies can be automatically installed."
    echo "OR"
    echo "   2) Install dependencies yourself: git curl zsh."
    return
  fi

  case $DIST in
    alpine)
      $Sudo apk add --update --no-cache git curl zsh
    ;;
    centos | amzn)
      $Sudo yum update -y
      $Sudo yum install -y git curl
      $Sudo yum install -y ncurses-compat-libs # this is required for AMZN Linux (ref: https://github.com/emqx/emqx/issues/2503)
      $Sudo curl http://mirror.ghettoforge.org/distributions/gf/el/7/plus/x86_64/zsh-5.1-1.gf.el7.x86_64.rpm > zsh-5.1-1.gf.el7.x86_64.rpm
      $Sudo rpm -i zsh-5.1-1.gf.el7.x86_64.rpm
      $Sudo rm zsh-5.1-1.gf.el7.x86_64.rpm
    ;;
    *)
      $Sudo apt-get update
      $Sudo apt-get -y install git curl zsh locales
      if [ "$VERSION" != "14.04" ]; then
        $Sudo apt-get -y install locales-all
      fi
      $Sudo locale-gen en_US.UTF-8
    ;;
  esac
}

init () {
  echo "### Installing ZSH"

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

          echo "###### Installing dependencies for macOS"
          softwareupdate --all --install --force
          echo "######## Done running software update"
        fi
      elif [ "${arch_name}" = "arm64" ]; then
        echo "Running on ARM"

        echo "###### Installing dependencies for macOS"
        softwareupdate --all --install --force
        softwareupdate --install-rosetta --agree-to-license
        echo "######## Done running software update"
      else
        echo "Unknown architecture: ${arch_name}"
      fi
      install_osx_dependencies
    ;;
    Linux)
      install_linux_dependencies
    ;;
  esac

  if [ -e "$HOME/.dotFiles" ]; then
    echo "###### Pulling changes into $HOME/.dotFiles"
    cd "$HOME/.dotFiles" && git stash -u && git pull
  else
    echo "###### Cloning ryan953/dotFiles ${BRANCH:-master}"
    # Using https transport because we havn't setup ssh keys yet!
    git clone -b ${BRANCH:-main} https://github.com/ryan953/dotFiles.git "$HOME/.dotFiles"
  fi

  "$HOME/.dotFiles/install-zsh.sh"
}

init
