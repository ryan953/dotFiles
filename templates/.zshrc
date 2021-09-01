export LANG='en_US.UTF-8'
export LANGUAGE='en_US:en'
export LC_ALL='en_US.UTF-8'
export TERM=xterm-256color

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# See the path with:
echo_path () {
    echo $PATH  | tr ':' '\n'
}
export PATH=$HOME/bin:$PATH

if command -v brew > /dev/null; then
    alias ctags="$(brew --prefix)/bin/ctags"
fi

# `curl -L git.io/antigen > dotFiles/templates/.antigen.zsh`
[[ -f ~/.antigen.zsh ]] && source ~/.antigen.zsh
[[ -f ~/.antigenrc ]] && antigen init ~/.antigenrc

# https://github.com/romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Override the generated .p10k.zsh file
[[ -f ~/.p10k.overrides.zsh ]] && source ~/.p10k.overrides.zsh

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

export EDITOR=$(command -v vim)
export VISUAL=$(command -v vim)
export BAT_THEME="TwoDark"

# When you start typing a command and then hit the up key, rather than just replacing
# what you already typed with the previous command, the shell will instead search
# for the latest command in the history starting with what you already typed.
bindkey '^[[A' up-line-or-search # up arrow
bindkey '^[[B' down-line-or-search # down arrow

### Aliases {{{

export TIME_STYLE=long-iso
alias cat='bat'

alias ll='exa -l --group --git'
alias la='exa -l --group --git --all'
alias tree='exa -l --group --git --all --tree --level=2'

alias ag='ag --hidden'
alias rg='rg --hidden'

alias top='htop'

# }}}

### FZF {{{
# `fd` config via: https://medium.com/better-programming/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d#6480

FZF_PREVIEW_FILES="([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {}))"
FZF_PREVIEW_DIRS="([[ -d {} ]] && (exa --tree --level 3 {} --color=always --all))"
FZF_PREVIEW="--preview '$FZF_PREVIEW_FILES || $FZF_PREVIEW_DIRS || echo {} 2> /dev/null | head -200'"
FZF_LAYOUT='--height 40% --inline-info'
FZF_OPTS="--preview-window=:hidden --bind '?:toggle-preview'"

if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d"

    _fzf_compgen_path() {
        fd --hidden --follow --exclude .git . "$1"
    }
    _fzf_compgen_dir() {
        fd --hidden --follow --exclude .git --type d . "$1"
    }
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --sort-files --files --hidden -g "!.git/"'
elif command -v ag &> /dev/null; then
    export FZF_DEFAULT_COMMAND='ag -l --hidden -g ""'
fi
export FZF_DEFAULT_OPTS="$FZF_PREVIEW"

#export FZF_CTRL_T_COMMAND=""
export FZF_CTRL_T_OPTS="$FZF_PREVIEW $FZF_LAYOUT $FZF_OPTS"
#export FZF_ALT_C_COMMAND=""
export FZF_ALT_C_OPTS="$FZF_PREVIEW $FZF_LAYOUT $FZF_OPTS"

# }}}

### Z with FZF {{{
# Via: https://medium.com/better-programming/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d

# like normal z when used with arguments but displays an fzf prompt when used without.
unalias z 2> /dev/null
z() {
    [ $# -gt 0 ] && _z "$*" && return
    cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

# }}}

### SSH Socket {{{

# Predictable SSH authentication socket location.
SOCK="/tmp/ssh-agent-$USER-screen"
if test $SSH_AUTH_SOCK && [ $SSH_AUTH_SOCK != $SOCK ]; then
    rm -f /tmp/ssh-agent-$USER-screen
    ln -sf $SSH_AUTH_SOCK $SOCK
    export SSH_AUTH_SOCK=$SOCK
fi

# }}}

### NVM {{{

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# }}}

# vim:foldmethod=marker:foldlevel=0
