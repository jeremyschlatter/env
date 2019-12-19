alias ls="ls -G --color=auto"

alias la="ls -A"
alias sl="ls"
alias ll="ls -l"
alias lrt="ls -lrt"

alias e="exa --classify"
alias ea="e --all"
alias ee="e --long --header --git"
alias ert="e --long --sort time"
alias et="e --tree"

alias "cd.."="cd .."
alias python="python -tt"
alias d=docker
alias g=git
alias gst="git status"
alias gdiff="git diff"
alias gadd="git add"

alias gotop="gotop -c default-dark"

alias cat="bat"

alias blaze=bazel

light() {
    kitty @ set-colors --configured --all ~/.nix-profile/config/kitty/light.conf
    echo light > ~/.config/colors
    eval "$(configure-colors)"
}
dark() {
    kitty @ set-colors --configured --all ~/.nix-profile/config/kitty/dark.conf
    echo dark > ~/.config/colors
    eval "$(configure-colors)"
}
