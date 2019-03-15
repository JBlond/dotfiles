#############
# git aliases
source ~/dotfiles/git/complete
complete -o default -o nospace -F _git git

alias ga="git add"
alias gbr="git branch"
alias gcfg="git config --list"
alias gcl="git clone --recurse-submodules"
alias gcma="git cma"
alias gcmap="git cmap"
alias gco="git checkout"
alias gd="git diff"
alias gdiff="git diff"
alias gg="git branch -vv"
alias ggc="git gc"
alias gh='cd "$(git rev-parse --show-toplevel)"'
alias gi="git init"
alias gib="git init --bare"
alias gitu="git cmapu"
alias gl="git lg"
alias glc="git diff @~..@"
alias gm="git checkout master"
alias gp="git pull"
alias gpn="git pull --no-ff"
alias gpo="git push origin"
alias gr="git remote -v"
alias gst="git status -sb"
alias gsu="git submodule update --recursive --remote"
