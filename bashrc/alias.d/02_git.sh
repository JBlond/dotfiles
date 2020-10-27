#############
# git aliases
source ~/dotfiles/git/complete
complete -o default -o nospace -F _git git

alias gcl="git clone --recurse-submodules"
alias gcma="git cma"
alias gcmap="git cmap"
alias gco="git checkout"
alias gd="git diff"
alias ggc="git gc"
alias gh='cd "$(git rev-parse --show-toplevel)"'
alias gst="git status -sb"
alias gsu="git submodule update --recursive --remote"
