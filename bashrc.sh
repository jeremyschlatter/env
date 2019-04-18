# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options.
HISTCONTROL=ignoredups

# Some aliases
source ~/.nix-profile/bash/bash_aliases.sh

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Configure prompt
reset='\[$(tput sgr0)\]'

bold='\[$(tput bold)\]'

black='\[$(tput setaf 0)\]'
red='\[$(tput setaf 1)\]'
green='\[$(tput setaf 2)\]'
yellow='\[$(tput setaf 3)\]'
blue='\[$(tput setaf 4)\]'
magenta='\[$(tput setaf 5)\]'
cyan='\[$(tput setaf 6)\]'
white='\[$(tput setaf 7)\]'

purple='\[\033[1;35m\]'
brown='\[\033[0;33m\]'
light_gray='\[\033[0;37m\]'

dot_ps1 ()
{
    # Disabled during transation away from vcsh.
    # May eventually be deleted.
    return

    # Return if not in $HOME.
    [ "`pwd`" == $HOME ] || return

    # Print notice if dirty dotfiles.
    [ -z "`dot status -s`" ] || echo " uncommitted dotfiles"
}

if [ -a ~/.local_bashrc ]; then
    source ~/.local_bashrc
fi

git_ps1 ()
{
    # Return if not git repo.
    git status &> /dev/null || return

    # Return if no branches
    [ `git branch | wc -l` -eq 0 ] && return

    # Print current branch name.
    echo -n " `git rev-parse --abbrev-ref HEAD`"

    # Print asterisk if dirty.
    [ -z "`git status -s`" ] || echo "*"
}
#prompt_base=$bold$red"\t "$cyan"(\$(pyenv version-name)) \W$purple\$(dot_ps1)$yellow\$(git_ps1)$cyan $ "$reset
prompt_base=$cyan"$MY_HOSTNAME"$bold$red"\t "$cyan"\W$purple\$(dot_ps1)$yellow\$(git_ps1)$cyan $ "$reset
PS1="$prompt_base"

# TODO: Remove the check for 130 if possible. I want it there for cases where I
# change my mind while typing a command, press ^C, and don't want my next prompt
# to be defiled with a bad return code just because of that. But maybe other
# programs will exit 130 without knowing the convention, and it might be useful
# to have the reminder when I ^C a long-running program.
prompt() {
    #status=`RET=$?; if [[ $RET != 0 ]] && [[ $RET != 130 ]]; then  echo -n "$RET "; fi`
    history -a
    history -n
    #PS1="$status$prompt_base"
    #PREV_PS1="$PS1"
    #echo -n "$status$prompt_base"
}
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} prompt"


# history nicities -- don't overwrite history, share history across tabs,
# longer history, store multi-line commands as a single command.
# From http://dancingpenguinsoflight.com/2008/11/bash-history-tips-and-tricks/
shopt -s histappend
HISTSIZE=100000
HISTFILESIZE=100000
shopt -s cmdhist

# don't filter duplicates or commands with leading whitespace from history
export HISTCONTROL=

set -o vi  # Use vi-mode editing on the command line.

# git tab completion, with 'g' alias
source ~/.nix-profile/bash/git-completion.bash
__git_complete g __git_main

# Add timestamps to bash history.
export HISTTIMEFORMAT="%F %T "

# Use vim for editing.
export SVN_EDITOR=vim
export EDITOR=vim

# Make git diff, and anything else that pipes through less,
# display utf-8 characters properly.
# Credit to http://stackoverflow.com/a/19436421
export LESSCHARSET=UTF-8

export BAT_THEME="Monokai Extended Light"

export XDG_CONFIG_HOME=$HOME/.nix-profile/config

# added by travis gem
[ -f /Users/jeremy/.travis/travis.sh ] && source /Users/jeremy/.travis/travis.sh

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
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
