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

# 'git pull --ff-only' with a short log of the latest changes
ff () {
    local HEADHASH=`git describe --always --abbrev=40`;
    git pull --ff-only $*;
    echo;
    PAGER='cat -B' git log --format="%C(yellow)%h %C(green)%an%C(reset): %s" $HEADHASH.. | sed -nr 's/([^:]+)\:/\1\t/;p';
}
