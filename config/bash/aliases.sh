alias e="exa --classify"
alias ea="e --all"
alias ee="e --long --header --git"
alias ert="e --long --sort time"
alias et="e --tree"

alias g=git
alias gst="g status"
alias gdiff="g diff"
alias gadd="g add"

alias "cd.."="cd .."
alias d=docker
alias c="gcloud compute"
alias cs="gcloud compute instances"

alias cat="bat"

alias vit='vi -c ":vsplit term://shell"'

clone() {
    eval "$(github $1)"
}

gitlab() {
    eval "$($NIX_PROFILE/bin/gitlab $1)"
}

alias light="colorscheme light"
alias dark="colorscheme dark"
