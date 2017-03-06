#!/bin/bash

mkdir -p "$HOME/.vim"

ln -s `pwd`/submodules/vim-monokai/colors/ "$HOME/.vim/colors" &> /dev/null
echo "Linked vim-monokai/colors to .vim/colors"
