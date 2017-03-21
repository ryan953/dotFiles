#!/usr/bin/env bash

backup_and_link() {
	local FILE=$1
	local DEST=$2

	if ! [ "$FILE" == '.' ] && ! [ "$FILE" == '..' ] && ! [ -d "$FILE" ]; then
		BASE=`basename "$FILE"`
		if [ -f "$DEST$BASE" ]; then
			! [ -f "$DEST$BASE.bak" ] && \
				echo "Linking $BASE"
				cp "$DEST$BASE" "$DEST$BASE.bak" && \
				echo "- Backed up $DEST$BASE"
		fi
		rm "$DEST$BASE"
		ln -s "$FILE" "$DEST$BASE"
		echo "Linked $BASE to $DEST$BASE"
	fi
}

for FILE in `pwd`/config/*; do
	backup_and_link "$FILE" "$HOME/."
done

mkdir "$HOME/bin/"
for FILE in `pwd`/bin/*; do
	backup_and_link "$FILE" "$HOME/bin/"
done

source $HOME/.bash_profile

OS="`uname`"
if [ $OS == "Darwin" ]; then
	echo "Installing MacOS Scripts"

	for FILE in `pwd`/config/ssh/*; do
		backup_and_link "$FILE" "$HOME/.ssh/"
	done

	# Homebrew
	if brew -h &> /dev/null; then
		echo "Found Homebrew"
	else
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		echo "Installed Homebrew"
	fi

	install_brew() {
		local BREW=${1}
		if brew ls --versions $BREW > /dev/null; then
			echo "Found $BREW"
			return 1
		else
			brew install $BREW
			echo "Installed $BREW"
			return 0
		fi
	}

	install_cask() {
		local CASK=${1}
		if brew cask ls --versions $CASK > /dev/null; then
			echo "Found $CASK"
			return 1
		else
			brew cask install $CASK
			echo "Installed $CASK"
			return 0
		fi
	}

	if ! [ -f "$HOME/.bash_homebrew_github_token" ]; then
		less `pwd`/install/homebrew/bash_homebrew_github_token.template > "$HOME/.bash_homebrew_github_token"
		echo "Visit https://github.com/settings/tokens and fill in ~/.bash_homebrew_github_token"
	fi

	if ! [ -f "$HOME/.gitconfig_local" ]; then
		less `pwd`/install/git/gitconfig_local > "$HOME/.gitconfig_local"
		echo "Add your custom git.name and git.email to ~/.gitconfig_local along with anything else you want"
	fi

	install_brew "flow"
	install_brew "fzf"
	install_brew "git" && ln -s `brew --prefix git`/share/git-core/contrib/diff-highlight/diff-highlight $HOME/bin/diff-highlight
	install_brew "node" && npm install -g yarn
	install_brew "tig"
	install_brew "tmux"
	install_brew "wget"
	install_cask "iterm2" && curl -L https://iterm2.com/misc/bash_startup.in > $HOME/bin/iterm2_shell_integration.bash
	install_brew "reattach-to-user-namespace"

	if install_cask "sublime-text"; then
		SUBL="$HOME/Library/Application Support/Sublime Text 3"
		wget -O "$SUBL/Installed Packages/Package Control.sublime-package" https://packagecontrol.io/Package%20Control.sublime-package

		for FILE in `pwd`/install/sublime-text/User/*; do
			backup_and_link "$FILE" "$SUBL/Packages/User/"
		done
	fi
else
	echo "Not on OSX"
	# # Ubuntu >= 13.10 (Saucy) or Debian >= 8 (Jessie)
	# apt-get install silversearcher-ag

	# # Fedora 21 and lower
	# yum install the_silver_searcher

	# # Fedora 22+
	# dnf install the_silver_searcher

	# # RHEL7+
	# yum install epel-release.noarch the_silver_searcher

	# # Gentoo
	# emerge the_silver_searcher

	# # Arch
	# pacman -S the_silver_searcher

	# # Slackware
	# sbopkg -i the_silver_searcher

	# # openSUSE:
	# zypper install the_silver_searcher
fi

if [ ! git st &> /dev/null ]; then
	git init
	git remote add origin git@github.com:ryan953/dotFiles.git
	git fetch
	git reset origin/master
fi

git submodule init
git submodule update

if ! [ -e "$HOME/bin/arc" ]; then
	ln -s `pwd`/submodules/arcanist/bin/arc "$HOME/bin/arc"

	# arc install-certificate
	# arc set-config editor vim
fi

DiffSoFancy=`pwd`/submodules/diff-so-fancy
backup_and_link "$DiffSoFancy/third_party/diff-highlight/diff-highlight" "$HOME/bin/"
backup_and_link "$DiffSoFancy/diff-so-fancy" "$HOME/bin/"
mkdir "$HOME/bin/libexec"
backup_and_link "$DiffSoFancy/libexec/diff-so-fancy.pl" "$HOME/bin/libexec/"

`pwd`/install/vim.sh

echo "You can extend this setup by adding the file \'~/.bash_profile_local\' and running \'source ~/.bash_profile\'"
