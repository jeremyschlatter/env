alias e="exa --classify"
alias ea="e --all"
alias ee="e --long --header --git"
alias ert="e --long --sort time"
alias et="e --tree"

alias g=git
alias gst="git status"
alias gdiff="git diff"
alias gadd="git add"

alias "cd.."="cd .."
alias python="python -tt"
alias d=docker
alias c="gcloud compute"
alias cs="gcloud compute instances"
alias ha="hass-cli"

alias gotop="gotop -c default-dark"

alias cat="bat"

alias vit='vi -c ":vsplit term://shell"'

light() {
    eval "$(pylight)"
}
dark() {
    eval "$(pydark)"
}
