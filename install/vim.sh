#!/usr/bin/env bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

VIM="$HOME/.vim/"

mkdir -p "$VIM"
mkdir -p "${VIM}tmp"
mkdir -p "${VIM}colors"

link_if() {
	local FILE=$1
	local DEST=$2

	BASE=$(basename "$FILE")

	if [ -h "$DEST$BASE" ]; then
		rm "$DEST$BASE"
	fi
	ln -s "$FILE" "$DEST$BASE"
	echo "Linked $FILE to $DEST$BASE"
}

# Link pathogen/autoload so it can find everything in "${VIM}/bundle"
link_if "$(pwd)/submodules/vim-pathogen/autoload" "$VIM"

DEST="${VIM}bundle/"
mkdir -p "$DEST"
for FILE in `pwd`/submodules/vim-bundle/*; do
	# Link everything from vim-bundle so pathogen finds it
	BASE=$(basename "$FILE")
	link_if "$FILE" "$DEST"

	# Also link any color theme and put them in ${VIM}/colors
	if [[ -d "$FILE/colors" ]] ; then
		for COLORFILE in $FILE/colors/*; do
			link_if "$COLORFILE" "${VIM}colors/"
		done
	fi
done

# This submodule was really installed to the wrong place, so link it manually
# Next time move it to vim-bundles
link_if $(pwd)/submodules/vim-one/colors/one.vim "${VIM}colors/"
