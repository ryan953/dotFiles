#!/usr/bin/env bash

VIM="$HOME/.vim/"

mkdir -p "$VIM"
mkdir -p "$VIM/tmp"

link_if() {
	local FILE=$1
	local DEST=$2

	BASE=`basename "$FILE"`

	if ! [ -e "$DEST$BASE" ]; then
		ln -s "$FILE" "$DEST$BASE"
		echo "Linked $FILE to $DEST$BASE"
	fi
}

link_if `pwd`/submodules/vim-monokai/colors "$VIM"
link_if `pwd`/submodules/vim-pathogen/autoload "$VIM"

DEST=""$VIM"bundle/"
mkdir -p "$DEST"
for FILE in `pwd`/submodules/vim-bundle/*; do
	BASE=`basename "$FILE"`
	link_if "$FILE" "$DEST"
done
