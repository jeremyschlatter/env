# If not running interactively, don't do anything
[ -z "$PS1" ] && return

shopt -s checkwinsize  # update LINES and COLUMNS after each command
shopt -s globstar      # allow recursive ** globs
set   -o vi            # use vi-mode editing on the command line

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Activate ble.sh. My primary motivation for this is to get
# atuin to work in bash. Atuin in bash requires either ble.sh
# or bash-preexec, with ble.sh being preferred:
#
#     https://docs.atuin.sh/guide/installation/#shell-plugin
#     https://github.com/atuinsh/docs/blob/c08b284a32ad32800565c4d0dbc2ca2a9477d104/src/content/docs/guide/installation.mdx?plain=1#L150-L158
#
# ble.sh also adds line-editing features to bash, which is cool I guess.
source $(blesh-share)/ble.sh
eval "$(_jeremy-shell-init bash)"

# source bash completions
#
# The system may have already loaded its own (older) bash-completion, e.g. via
# Ubuntu's /etc/profile.d/bash_completion.sh. Clear its guard variable so we
# load the nix one instead. It also loads $NIX_PROFILE/etc/bash_completion.d.
unset BASH_COMPLETION_VERSINFO
. $NIX_PROFILE/share/bash-completion/bash_completion
. $NIX_PROFILE/share/bash-completion/completions/git

# git tab completion with 'g' alias
__git_complete g __git_main

if [ -a ~/.local_bashrc ]; then
    source ~/.local_bashrc
fi
