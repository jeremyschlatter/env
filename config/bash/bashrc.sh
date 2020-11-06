# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# allow recursive ** globs
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -a ~/.local_bashrc ]; then
    source ~/.local_bashrc
fi

NIX_PROFILE=$HOME/.nix-profile

# Some aliases
. $NIX_PROFILE/config/bash/aliases.sh

# Set env vars
NIX_PROFILE=$NIX_PROFILE . $NIX_PROFILE/config/bash/env.sh

prompt() {
    # https://www.jefftk.com/p/you-should-be-logging-shell-history
    # I'm using a refined version from the one shown in the post.
    # It uses logfmt to disambiguate spaces, and also logs the timezone.
    # I also hooked ctrl-r up to read from this log.
    $NIX_PROFILE/bin/add-hist "$(history 1)"
}
PROMPT_COMMAND=prompt

set -o vi  # Use vi-mode editing on the command line.

source $NIX_PROFILE/etc/profile.d/bash_completion.sh

# source bash completions
for completion in $NIX_PROFILE/etc/bash_completion.d/*; do
    . $completion
done

# git tab completion with 'g' alias
source $NIX_PROFILE/share/bash-completion/completions/git
__git_complete g __git_main

# Add timestamps to bash history.
export HISTTIMEFORMAT="%F %T "

# Workaround for issue with nix's Go package on macOS:
#   https://github.com/NixOS/nixpkgs/issues/56348#issuecomment-482930309
if [ `uname` == "Darwin" ]; then
  export CC=clang
fi

# Set color-related env variables according to the current color scheme
eval "$(colorscheme restore-colors)"

. $NIX_PROFILE/share/fzf/key-bindings.bash
__fzf_history__() {
  # This overrides the __fzf_history__ implementation from key-bindings.bash.
  # It reads from ~/.full_history.logfmt rather than ~/.bash_history.
  local output
  output=$($NIX_PROFILE/bin/fzf-hist |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS --tac --sync --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS +m" $(__fzfcmd)
  ) || return
  READLINE_LINE=${output#*$'\t'}
  if [ -z "$READLINE_POINT" ]; then
    echo "$READLINE_LINE"
  else
    READLINE_POINT=0x7fffffff
  fi
}
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
bind -x '"\C-p": vim $(fzf);'

# http://owen.cymru/sf-a-quick-way-to-search-for-some-thing-in-bash-and-edit-it-with-vim-2/#ampshare=http://owen.cymru/sf-a-quick-way-to-search-for-some-thing-in-bash-and-edit-it-with-vim-2/
sf() {
  if [ "$#" -lt 1 ]; then echo "Supply string to search for!"; return 1; fi
  printf -v search "%q" "$*"
  include="yml,js,json,php,md,styl,pug,jade,html,config,py,cpp,c,go,hs,rb,conf,fa,lst"
  exclude=".config,.git,node_modules,vendor,build,yarn.lock,*.sty,*.bst,*.coffee,dist"
  rg_command='rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --color "always" -g "*.{'$include'}" -g "!{'$exclude'}/*"'
  files=`eval $rg_command $search | fzf --ansi --multi --reverse | awk -F ':' '{print $1":"$2":"$3}'`
  [[ -n "$files" ]] && ${EDITOR:-vim} $files
}

eval "$(direnv hook bash)"

eval "$(starship init bash)"
