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

# Use fzf with: The Silver Searcher
# export FZF_DEFAULT_COMMAND='ag -l --hidden -g ""'
# Use fzf with: ripgrep
export FZF_DEFAULT_COMMAND='rg --files --hidden'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --inline-info'

# `curl -L git.io/antigen > dotFiles/templates/.antigen.zsh`
[[ ! -f ~/.antigen.zsh ]] || source ~/.antigen.zsh
antigen init ~/.antigenrc

# https://github.com/romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Override the generated .p10k.zsh file
[[ ! -f ~/.p10k.overrides.zsh ]] | source ~/.p10k.overrides.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# When you start typing a command and then hit the up key, rather than just replacing
# what you already typed with the previous command, the shell will instead search
# for the latest command in the history starting with what you already typed.
bindkey '^[[A' up-line-or-search # up arrow
bindkey '^[[B' down-line-or-search # down arrow

# Predictable SSH authentication socket location.
SOCK="/tmp/ssh-agent-$USER-screen"
if test $SSH_AUTH_SOCK && [ $SSH_AUTH_SOCK != $SOCK ]; then
	rm -f /tmp/ssh-agent-$USER-screen
	ln -sf $SSH_AUTH_SOCK $SOCK
	export SSH_AUTH_SOCK=$SOCK
fi

[[ ! -f ~/.zsh.local ]] | source ~/.zsh.local
