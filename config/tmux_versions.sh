#!/usr/bin/env bash

verify_tmux_version () {
    local tmux_version="$(tmux -V | cut -c 6- | tr -dc '0-9.')"

    if [[ $(echo "$tmux_version >= 2.1" | bc) -eq 1 ]] ; then
        tmux source-file "$HOME/.tmux_2.1_up.conf"
        exit
    elif [[ $(echo "$tmux_version >= 1.9" | bc) -eq 1 ]] ; then
        tmux source-file "$HOME/.tmux_1.9_to_2.1.conf"
        exit
    else
        tmux source-file "$HOME/.tmux_1.9_down.conf"
        exit
    fi
}

verify_tmux_version

