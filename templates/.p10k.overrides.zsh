() {
  # Formatter for Git status.
  #
  # Example output: master ⇣42⇡42 *42 merge ~42 +42 !42 ?42.
  #
  # You can edit the function to customize how Git status looks.
  #
  # VCS_STATUS_* parameters are set by gitstatus plugin. See reference:
  # https://github.com/romkatv/gitstatus/blob/master/gitstatus.plugin.zsh.
  function ryans_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      # If P9K_CONTENT is not empty, use it. It's either "loading" or from vcs_info (not from
      # gitstatus plugin). VCS_STATUS_* parameters are not available in this case.
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    local my_branch_color='%B%1F'  # bold & red foreground
    if (( $1 )); then
      # Styling for up-to-date Git status.
      local       meta='%f'   # default foreground
      local      clean='%2F'  # green foreground
    else
      # Styling for incomplete and stale Git status.
      local       meta='%f'  # default foreground
      local      clean='%f'  # default foreground
    fi

    local res
    local where  # branch or tag
    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}"
      where=${(V)VCS_STATUS_LOCAL_BRANCH}
    elif [[ -n $VCS_STATUS_TAG ]]; then
      res+="${meta}#"
      where=${(V)VCS_STATUS_TAG}
    fi

    # If local branch name or tag is at most 32 characters long, show it in full.
    # Otherwise show the first 12 … the last 12.
    # Tip: To always show local branch name in full without truncation, delete the next line.
    (( $#where > 32 )) && where[13,-13]="…"

    res+="${my_branch_color}${where//\%/%%}"  # escape %

    # Display the current Git commit if there is no branch or tag.
    # Tip: To always display the current Git commit, remove `[[ -z $where ]] &&` from the next line.
    [[ -z $where ]] && res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    typeset -g ryans_git_format=$res
  }

  functions -M ryans_git_formatter 2>/dev/null

  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((ryans_git_formatter(1)))+${ryans_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((ryans_git_formatter(0)))+${ryans_git_format}}'

  function prompt_dotfile_repo_state() {
    pushd ~/.dotFiles &> /dev/null
    git fetch origin
    __GIT_PROMPT_DIR=~/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git-prompt
    local gitstatus="$__GIT_PROMPT_DIR/gitstatus.py"
    popd &> /dev/null

    _GIT_STATUS=$(python ${gitstatus} 2>/dev/null)
    __CURRENT_GIT_STATUS=("${(@s: :)_GIT_STATUS}")
    GIT_BRANCH=$__CURRENT_GIT_STATUS[1]
    GIT_AHEAD=$__CURRENT_GIT_STATUS[2]
    GIT_BEHIND=$__CURRENT_GIT_STATUS[3]
    GIT_STAGED=$__CURRENT_GIT_STATUS[4]
    GIT_CONFLICTS=$__CURRENT_GIT_STATUS[5]
    GIT_CHANGED=$__CURRENT_GIT_STATUS[6]
    GIT_UNTRACKED=$__CURRENT_GIT_STATUS[7]

    DIRTY=''
    if [ "$GIT_AHEAD" -ne "0" ]; then
      DIRTY='%B%1FdotFiles ✘'
    fi
    if [ "$GIT_BEHIND" -ne "0" ]; then
      DIRTY='%B%1FdotFiles ✘'
    fi
    if [ "$GIT_STAGED" -ne "0" ]; then
      DIRTY='%B%1FdotFiles ✘'
    fi
    if [ "$GIT_CONFLICTS" -ne "0" ]; then
      DIRTY='%B%1FdotFiles ✘'
    fi
    if [ "$GIT_CHANGED" -ne "0" ]; then
      DIRTY='%B%1FdotFiles ✘'
    fi
    if [ "$GIT_UNTRACKED" -ne "0" ]; then
      DIRTY='%B%1FdotFiles ✘'
    fi

    p10k segment -f 240 -t "${DIRTY}"
  }

  (( ! $+functions[p10k] )) || p10k reload
}
