#add sbin's to prompt
PATH="/sbin/:/usr/local/sbin:/usr/local/bin:$PATH"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups
# ... and ignore same sucessive entries.
export HISTCONTROL=ignoreboth

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

HISTSIZE=2000
HISTFILESIZE=4000

source ~/dotfiles/less.sh

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

source ~/dotfiles/lscolors.sh
source ~/dotfiles/.git-prompt.sh
source ~/dotfiles/.git_functions.sh

bold=$(tput bold)

PS1='${debian_chroot:+($debian_chroot)}\[\033[1;36m\]\u\[\033[01;32m\]@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
PS1="$PS1"'\[\033[36m\]'
PS1="$PS1"'`__git_ps1`'
# commenting out the next two lines will increase the speed inside a repo alot
PS1="$PS1"'`find_git_commit_diff`'
PS1="$PS1"'\[\033[1m\033[33m\]`find_git_dirty`'
PS1="$PS1"'\[\033[0;31m\]\nλ\[\033[0m\] '

source ~/dotfiles/xterm
source ~/dotfiles/aliases.sh
source ~/dotfiles/bash_completion
source ~/dotfiles/less.sh
source ~/dotfiles/complete_ssh_hosts.sh
source ~/dotfiles/functions.sh
