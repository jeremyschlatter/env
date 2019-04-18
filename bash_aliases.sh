if test -n "$LINUX"; then
    alias ls="ls -G --color=auto"
else
    alias ls="ls -G"
fi
alias la="ls -A"
alias sl="ls"
alias l="ls"
alias ll="ls -l"
alias lrt="ls -lrt"
alias "cd.."="cd .."
alias python="python -tt"
alias dot="vcsh dot"
alias grep="grep --color"
alias c=conda
alias d=docker
alias g=git
alias gst="git status"
alias gdiff="git diff"
alias gadd="git add"

alias nst="n status"
alias ndiff="n diff"
alias nadd="n add"
alias ned="n edit"
alias ncat="n cat"
alias m="n message"
