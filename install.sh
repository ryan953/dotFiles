#!/usr/bin/env bash

backup_and_link() {
	local file=$1
	local dest=$2

	if ! [ "$file" == '.' ] && ! [ "$file" == '..' ] && ! [ -d "$file" ]; then
		base=$(basename "$file")
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

copy_into() {
	local file=$1
	local dest=$2

	if ! [ "$file" == '.' ] && ! [ "$file" == '..' ] && ! [ -d "$file" ]; then
		base=$(basename "$file")
		if ! [ -f "$dest$base" ]; then
			cat "$file" > "$dest$base"
			echo "Cloned $base to $dest$base"
		else
			echo "Skipping cloning $base into $dest$base"
		fi
	fi
}

print_check() {
	printf "\033[1;32m✔\033[0m "
}
print_warn() {
	printf "\033[1;31m⚠\033[0m "
}
print_error() {
	printf "\033[1;31m✘\033[0m "
}

for file in $(pwd)/config/*; do
	backup_and_link "$file" "$HOME/."
done

for file in $(pwd)/install/templates/*; do
	copy_into "$file" "$HOME/."
done

for file in $(pwd)/install/templates/ssh/*; do
	copy_into "$file" "$HOME/.ssh/"
done

mkdir -p "$HOME/bin/"
for file in $(pwd)/bin/*; do
	backup_and_link "$file" "$HOME/bin/"
done

source "$HOME/.bash_profile"

os=$(uname)
if [ "$os" == "Darwin" ]; then
	echo "Installing MacOS Scripts"

	for file in $(pwd)/config/ssh/*; do
		backup_and_link "$file" "$HOME/.ssh/"
	done

	if grep .dotFiles/install/iterm/ < ~/Library/Preferences/com.googlecode.iterm2.plist > /dev/null; then
		echo "iTerm2 prefs appears correct"
	else
		backup_and_link "$(pwd)/install/iterm/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/"
		defaults read com.googlecode.iterm2 > /dev/null
		echo "Set iTerm2 Prefs"
		print_warn && echo "Click 'Save Current Settings to Folder' Button in iTerm2 Prefs window"
	fi

	# Homebrew
	if brew -h &> /dev/null; then
		echo "Found Homebrew"
	else
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		echo "Installed Homebrew"
	fi

	install_brew() {
		local brew=${1}
		if brew ls --versions "$brew" > /dev/null; then
			echo "Found brew $brew"
			return 1
		else
			brew install "$brew"
			echo "Installed brew $brew"
			return 0
		fi
	}

	install_cask() {
		local cask=${1}
		if brew cask ls --versions "$cask" > /dev/null; then
			echo "Found brew-cask $cask"
			return 1
		else
			brew cask install "$cask"
			echo "Installed brew-cask $cask"
			return 0
		fi
	}

	install_brew "bash"
	install_brew "bash-completion"
	install_brew "ctags"
	install_brew "flow"
	install_brew "fswatch"
	install_brew "fzf"
	install_brew "git" && ln -s "$(brew --prefix git)/share/git-core/contrib/diff-highlight/diff-highlight" "$HOME/bin/diff-highlight"
	install_brew "git-extras"
	install_brew "node" && npm install -g yarn
	install_brew "reattach-to-user-namespace"
	install_brew "shellcheck"
	install_brew "the_silver_searcher"
	install_brew "tig"
	install_brew "tmux"
	install_brew "vim"
	install_brew "wget"
	install_brew "yarn"
	install_cask "atom" && apm starred --install
	install_cask "docker-toolbox"
	install_cask "iterm2" && curl -L https://iterm2.com/shell_integration/bash > "$HOME/bin/iterm2_shell_integration.bash"
	install_cask "java"

	if install_cask "sublime-text"; then
		subl="$HOME/Library/Application Support/Sublime Text 3"
		wget -O "$subl/Installed Packages/Package Control.sublime-package" https://packagecontrol.io/Package%20Control.sublime-package

		for file in $(pwd)/install/sublime-text/User/*; do
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

if ! git st &> /dev/null; then
	git init
	git remote add origin git@github.com:ryan953/dotFiles.git
	git fetch
	git reset origin/master
fi

git submodule init
git submodule update

if ! [ -e "$HOME/bin/arc" ]; then
	ln -s "$(pwd)/submodules/arcanist/bin/arc" "$HOME/bin/arc"

	# arc install-certificate
	# arc set-config editor vim
fi

DiffSoFancy=$(pwd)/submodules/diff-so-fancy
backup_and_link "$DiffSoFancy/third_party/diff-highlight/diff-highlight" "$HOME/bin/"
backup_and_link "$DiffSoFancy/diff-so-fancy" "$HOME/bin/"
mkdir -p "$HOME/bin/libexec"
backup_and_link "$DiffSoFancy/libexec/diff-so-fancy.pl" "$HOME/bin/libexec/"

"$(pwd)/install/vim.sh"

has_statements() {
	local file=$1
	local line_count
	line_count=$(grep --invert-match --extended-regexp --count --regexp='(^\s?#)|(^\s*?$)' "$file")
	if [ "$line_count" == 0 ]; then
		return 1
	else
		return 0
	fi
}

check_install_sh() {
	shellcheck ./*.sh ./config/bash_profile
}

check_has_bash_profile_local() {
	if has_statements "$HOME/.bash_profile.local"; then
		print_check
		echo 'Checked ~/.bash_profile.local'
	else
		print_error
		echo "Update ~/.bash_profile.local and run 'source ~/.bash_profile'"
	fi
}

check_has_gitconfig_local() {
	# Via: https://orrsella.com/2013/08/10/git-using-different-user-emails-for-different-repositories/

	if [[ -f "$HOME/.gitconfig.local" ]]; then
		# if `git --version` > 2.8; then
		if git config --global --includes --get user.email > /dev/null; then
			print_error
			echo "Remove user.email from ~/.gitconfig.local. 'useConfigOnly' will force us to have per-repo settings everywhere."
		else
			print_check
			echo "Checked ~/.gitconfig.local"
		fi
	else
		print_error
		echo "Missing ~/.gitconfig.local."
	fi
}

check_has_ssh_config_local() {
	if has_statements "$HOME/.ssh/config.local"; then
		print_check
	else
		print_error
	fi
	echo "Checked ~/.ssh/config.local"
}

echo ""
echo "You can extend this setup by adding/editing the files:"
check_has_bash_profile_local
check_has_gitconfig_local
check_has_ssh_config_local
