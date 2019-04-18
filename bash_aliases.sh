if [ `uname` == "Darwin" ]; then
    alias lss="/bin/ls -G"
else
    alias lss="/bin/ls -G --color=auto"
fi

alias ls=exa
alias la="exa --classify --all"
alias ea=la
alias ll="exa --classify --long --header --git"
alias el=ll
alias ee=ll
alias lrt="exa --classify --long --reverse --sort time"
alias ert=lrt
alias l="exa --classify"
alias e=l
alias et="e --tree"

alias "cd.."="cd .."
alias python="python -tt"
alias dot="vcsh dot"
alias grep="grep --color"
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
