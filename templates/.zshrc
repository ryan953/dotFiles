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

# NVM env vars must be set before zsh-nvm plugin is loaded
# https://github.com/lukechilds/zsh-nvm
export NVM_AUTO_LOAD=true
export NVM_AUTO_USE=true
export NVM_COMPLETION=true
export NVM_LAZY_LOAD=true
export NVM_DIR="$HOME/.nvm"

export EDITOR=$(command -v vim)
export VISUAL=$(command -v vim)
export BAT_THEME="TwoDark"

# When you start typing a command and then hit the up key, rather than just replacing
# what you already typed with the previous command, the shell will instead search
# for the latest command in the history starting with what you already typed.
bindkey '^[[A' up-line-or-search # up arrow
bindkey '^[[B' down-line-or-search # down arrow

####################################
# Open/Close folds with:      `za` #
# Map leader key is:          `\`  #
####################################

### Aliases {{{

export TIME_STYLE=long-iso
alias cat='bat'

alias ll='eza -l --group --git'
alias la='eza -l --group --git --all'
alias tree='eza -l --group --git --all --tree --level=2'

alias ag='ag --hidden'
alias rg='rg --hidden'

alias top='htop'

alias claude='brew upgrade -q claude-code && claude'
export CLAUDE_POWERLINE_THEME=tokyo-night
export CLAUDE_POWERLINE_STYLE=powerline
export CLAUDE_POWERLINE_DEBUG=0

pbcopy () {
    cat $@ | command pbcopy;
}

# }}}

### FZF {{{
# `fd` config via: https://medium.com/better-programming/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d#6480

FZF_PREVIEW_FILES="([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {}))"
FZF_PREVIEW_DIRS="([[ -d {} ]] && (eza --tree --level 3 {} --color=always --all))"
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

### Volta {{{

if [ -d "$HOME/.volta" ]; then
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"
fi

# }}}

### Homebrew on x86 or ARM {{{

# Must be loaded before zinit to ensure brew completions are in fpath
OS="$(uname)"
case $OS in
  Darwin)
    arch_name="$(uname -m)"
    if [ "${arch_name}" = "x86_64" ]; then
      if [ "$(sysctl -in sysctl.proc_translated)" = "1" ]; then
        # Running on Rosetta 2
      else
        # Running on Native Intel
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    elif [ "${arch_name}" = "arm64" ]; then
      # Running on Arm
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      # Running on another architecture
    fi

    export HOMEBREW_CASK_OPTS=--no-quarantine
  ;;
esac

# }}}


### Direnv {{{

# Lazy-load direnv to speed up shell startup
if command -v direnv &>/dev/null; then
  direnv() {
    unset -f direnv
    eval "$(command direnv hook zsh)"
    direnv "$@"
  }
fi

# }}}

### GCloud CLI {{{

# Load PATH immediately (lightweight)
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# Lazy-load gcloud completions (heavier)
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  gcloud() {
    unset -f gcloud
    source "$HOME/google-cloud-sdk/completion.zsh.inc"
    gcloud "$@"
  }
fi

# }}}

### ngrok {{{

# Lazy-load ngrok completions
if command -v ngrok &>/dev/null; then
  ngrok() {
    unset -f ngrok
    eval "$(command ngrok completion)"
    ngrok "$@"
  }
fi

# }}}

### Dex Tasks tooling {{{

# claude plugin marketplace add dcramer/dex
# claude plugin install dex@dex
# npx skills add dcramer/dex
# npm install -g @zeeg/dex

# Lazy-load dex completions
if command -v dex &>/dev/null; then
  dex() {
    unset -f dex
    eval "$(command dex completion zsh)"
    dex "$@"
  }
fi
# }}}

### Zinit Plugin Manager {{{

# Initialize Zinit
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
    print -P "%F{33} %F{34}Installation successful.%f%b" || \
    print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Initialize completions immediately (prevents "no tags registered" error)
zicompinit

# Load powerlevel10k theme (no turbo mode for instant prompt)
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Oh-My-Zsh library and plugins (turbo mode)
zinit wait lucid for \
  OMZL::git.zsh \
  OMZP::colored-man-pages \
  OMZP::command-not-found \
  OMZP::safe-paste \
  OMZP::z

# Other plugins (turbo mode)
zinit wait lucid for \
  changyuheng/fz \
  lukechilds/zsh-nvm \
  lukechilds/zsh-better-npm-completion

# Completions - load in turbo mode and replay
zinit wait lucid atload"zicdreplay" for \
  zsh-users/zsh-completions

# Autosuggestions - load in turbo mode
zinit wait lucid atload"_zsh_autosuggest_start" for \
  zsh-users/zsh-autosuggestions

# Syntax highlighting - must load before history-substring-search
zinit wait lucid for \
  zsh-users/zsh-syntax-highlighting

# History substring search - must load after syntax highlighting
zinit wait lucid for \
  zsh-users/zsh-history-substring-search

# https://github.com/romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Override the generated .p10k.zsh file
[[ -f ~/.p10k.overrides.zsh ]] && source ~/.p10k.overrides.zsh

[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh

# }}}

# vim: set ts=2 sw=2 et foldmethod=marker foldlevel=0:
