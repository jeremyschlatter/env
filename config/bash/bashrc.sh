# If not running interactively, don't do anything
[ -z "$PS1" ] && return

shopt -s checkwinsize  # update LINES and COLUMNS after each command
shopt -s globstar      # allow recursive ** globs
set   -o vi            # use vi-mode editing on the command line

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

export NIX_PROFILE=$HOME/.nix-profile

# source bash completions
if [ -d $NIX_PROFILE/etc/bash_completion.d ]; then
    for completion in $NIX_PROFILE/etc/bash_completion.d/*; do
        . $completion
    done
fi
if [ -d $NIX_PROFILE/share/bash_completion ]; then
    for completion in $NIX_PROFILE/share/bash_completion/*; do
        . $completion
    done
fi

. $NIX_PROFILE/config/bash/aliases.sh   # Some aliases
. $NIX_PROFILE/config/bash/env.sh       # Set env vars
. $NIX_PROFILE/etc/profile.d/bash_completion.sh
. $NIX_PROFILE/share/bash-completion/completions/git

# git tab completion with 'g' alias
__git_complete g __git_main

colorscheme restore-colors
eval "$(direnv hook bash)"
eval "$(mcfly init bash)"
eval "$(starship init bash)"
eval "$(zoxide init bash)"

if [ -a ~/.local_bashrc ]; then
    source ~/.local_bashrc
fi
