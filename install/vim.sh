#!/bin/bash

mkdir -p "$HOME/.vim"

ln -s `pwd`/../submodules/vim-monokai/colors/ "$HOME/.vim/colors"
echo "Linked monokai.vim to .vim/colors/"
