#!/usr/bin/env bash

verify_tmux_version () {
    # Strip the leading `tmux ` and any trailing chars as in `3.0a` => `3.0`
    local tmux_version="$(tmux -V | cut -c 6- | sed 's/[a-z]/ /g')"

    # Use $HOME and not ~ because this runs within tmux, not an env that will understand the tilde.
    if [[ $(echo "$tmux_version >= 2.3" | bc) -eq 1 ]] ; then
        tmux source-file "$HOME/.tmux/version_2.3_up.conf"
    elif [[ $(echo "$tmux_version >= 2.1" | bc) -eq 1 ]] ; then
        tmux source-file "$HOME/.tmux/version_2.1_up.conf"
    elif [[ $(echo "$tmux_version >= 1.9" | bc) -eq 1 ]] ; then
        tmux source-file "$HOME/.tmux/version_1.9_to_2.1.conf"
    else
        tmux source-file "$HOME/.tmux/version_1.9_down.conf"
    fi
}

verify_tmux_version
