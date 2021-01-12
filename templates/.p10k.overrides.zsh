() {
  # Formatter for Git status.
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
    [[ -n $VCS_STATUS_ACTION ]] && res+=" ${my_branch_color}(${VCS_STATUS_ACTION})"

    typeset -g ryans_git_format=$res
  }

  functions -M ryans_git_formatter 2>/dev/null

  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((ryans_git_formatter(1)))+${ryans_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((ryans_git_formatter(0)))+${ryans_git_format}}'

  (( ! $+functions[p10k] )) || p10k reload
}
