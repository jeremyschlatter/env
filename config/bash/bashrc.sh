# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# allow recursive ** globs
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

export NIX_PROFILE=$HOME/.nix-profile

# Some aliases
. $NIX_PROFILE/config/bash/aliases.sh

# Set env vars
. $NIX_PROFILE/config/bash/env.sh

set -o vi  # Use vi-mode editing on the command line.

source $NIX_PROFILE/etc/profile.d/bash_completion.sh

# source bash completions
if [ -d $NIX_PROFILE/etc/bash_completion.d ]; then
    for completion in $NIX_PROFILE/etc/bash_completion.d/*; do
        . $completion
    done
fi

# git tab completion with 'g' alias
source $NIX_PROFILE/share/bash-completion/completions/git
__git_complete g __git_main

# Set color-related env variables according to the current color scheme
eval "$(colorscheme restore-colors)"

eval "$(direnv hook bash)"
eval "$(mcfly init bash)"
eval "$(starship init bash)"
eval "$(zoxide init bash)"

if [ -a ~/.local_bashrc ]; then
    source ~/.local_bashrc
fi
