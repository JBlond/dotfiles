source ~/dotfiles/bashrc/path.sh

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

source ~/dotfiles/bashrc/history.sh
source ~/dotfiles/bashrc/terminal_options.sh
source ~/dotfiles/bashrc/less.sh
source ~/dotfiles/bashrc/lscolors.sh
source ~/dotfiles/bashrc/_docker.sh
source ~/dotfiles/bashrc/aliases.sh
source ~/dotfiles/bashrc/bash_completion.sh
source ~/dotfiles/bashrc/complete_ssh_hosts.sh
source ~/dotfiles/bashrc/functions.sh
source ~/dotfiles/bashrc/git_functions.sh
source ~/dotfiles/bashrc/git-prompt.sh
source ~/dotfiles/bashrc/ps1.sh
