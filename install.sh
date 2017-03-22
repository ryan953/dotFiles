#!/usr/bin/env bash

backup_and_link() {
	local file=$1
	local dest=$2

	if ! [ "$file" == '.' ] && ! [ "$file" == '..' ] && ! [ -d "$file" ]; then
		base=`basename "$file"`
		if [ -f "$dest$base" ] && ! [ -e "$dest$base" ]; then
			! [ -f "$dest$base.bak" ] && \
				cp "$dest$base" "$dest$base.bak" && \
				echo "- Backed up $dest$base"
		fi
		rm "$dest$base"
		ln -s "$file" "$dest$base"
		echo "Linked $base to $dest$base"
	fi
}

for file in `pwd`/config/*; do
	backup_and_link "$file" "$HOME/."
done

mkdir -p "$HOME/bin/"
for file in `pwd`/bin/*; do
	backup_and_link "$file" "$HOME/bin/"
done

source $HOME/.bash_profile

os="`uname`"
if [ $os == "Darwin" ]; then
	echo "Installing MacOS Scripts"

	for file in `pwd`/config/ssh/*; do
		backup_and_link "$file" "$HOME/.ssh/"
	done

	# Homebrew
	if brew -h &> /dev/null; then
		echo "Found Homebrew"
	else
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		echo "Installed Homebrew"
	fi

	install_brew() {
		local brew=${1}
		if brew ls --versions $brew > /dev/null; then
			echo "Found brew $brew"
			return 1
		else
			brew install $brew
			echo "Installed brew $brew"
			return 0
		fi
	}

	install_cask() {
		local cask=${1}
		if brew cask ls --versions $cask > /dev/null; then
			echo "Found brew-cask $cask"
			return 1
		else
			brew cask install $cask
			echo "Installed brew-cask $cask"
			return 0
		fi
	}

	if ! [ -f "$HOME/.bash_homebrew_github_token" ]; then
		less `pwd`/install/homebrew/bash_homebrew_github_token.template > "$HOME/.bash_homebrew_github_token"
		echo "Visit https://github.com/settings/tokens and fill in ~/.bash_homebrew_github_token"
	fi

	if ! [ -f "$HOME/.gitconfig.local" ]; then
		less `pwd`/install/git/gitconfig.local > "$HOME/.gitconfig.local"
		echo "Add your custom git.name and git.email to ~/.gitconfig.local along with anything else you want"
	fi

	install_brew "flow"
	install_brew "fzf"
	install_brew "git" && ln -s `brew --prefix git`/share/git-core/contrib/diff-highlight/diff-highlight $HOME/bin/diff-highlight
	install_brew "node" && npm install -g yarn
	install_brew "the_silver_searcher"
	install_brew "tig"
	install_brew "tmux"
	install_brew "wget"
	install_cask "iterm2" && curl -L https://iterm2.com/misc/bash_startup.in > $HOME/bin/iterm2_shell_integration.bash
	install_brew "reattach-to-user-namespace"

	if install_cask "sublime-text"; then
		subl="$HOME/Library/Application Support/Sublime Text 3"
		wget -O "$subl/Installed Packages/Package Control.sublime-package" https://packagecontrol.io/Package%20Control.sublime-package

		for file in `pwd`/install/sublime-text/User/*; do
			backup_and_link "$file" "$subl/Packages/User/"
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
mkdir -p "$HOME/bin/libexec"
backup_and_link "$DiffSoFancy/libexec/diff-so-fancy.pl" "$HOME/bin/libexec/"

`pwd`/install/vim.sh

check_if_file() {
	file=$1
	message=$2

	if [[ -f "$file" ]]; then
		out="\033[1;32m✔\033[0m"
	else
		out="\033[1;31m✘\033[0m"
	fi

	printf " $out $message\n"
}

echo ""
echo "You can extend this setup by adding/editing the files:"
check_if_file "$HOME/.bash_profile.local" "~/.bash_profile.local then run 'source ~/.bash_profile'"
check_if_file "$HOME/.bash_homebrew_github_token" "~/.bash_homebrew_github_token"
check_if_file "$HOME/.gitconfig.local" "~/.gitconfig.local"
check_if_file "$HOME/.ssh/config.local" "~/.ssh/config.local"

