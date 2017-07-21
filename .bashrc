#add sbin's to prompt
PATH="/sbin/:/usr/local/sbin:/usr/local/bin:$PATH"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups
# ... and ignore same sucessive entries.
export HISTCONTROL=ignoreboth

export PAGER=less

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

HISTSIZE=2000
HISTFILESIZE=4000

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

source ~/dotfiles/lscolors.sh

source ~/dotfiles/.git-prompt.sh

find_git_dirty () {
  if [[ ! -z $(__git_ps1) && -n $(git status --porcelain) ]]; then echo "*"; fi
}

find_git_commit_diff () {
  if [[ ! -z $(__git_ps1) ]]; then
    commit_diff=$(git for-each-ref --format="%(push:track)" refs/heads)
    commit_diff=${commit_diff//ahead\ /\+}
    commit_diff=${commit_diff//behind\ /\-}
    echo $commit_diff
  fi
}

PS1='${debian_chroot:+($debian_chroot)}\[\033[1;36m\]\u\[\033[01;32m\]@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
PS1="$PS1"'\[\033[36m\]'
PS1="$PS1"'`__git_ps1`'
# commenting out the next two lines will increase the speed inside a repo alot
PS1="$PS1"'`find_git_commit_diff`'
PS1="$PS1"'\[\033[31m\]`find_git_dirty`'
PS1="$PS1"'\[\033[0;31m\]\nλ\[\033[0m\] '


# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
    ;;
*)
    ;;
esac

source ~/dotfiles/aliases.sh

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

_complete_ssh_hosts () {
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    comp_ssh_hosts=`cat ~/.ssh/known_hosts | \
                    cut -f 1 -d ' ' | \
                    sed -e s/,.*//g | \
                    grep -v ^# | \
                    uniq | \
                    grep -v "\[" ;
            cat ~/.ssh/config | \
                    grep "^Host " | \
                    awk '{print $2}'
            `
    COMPREPLY=( $(compgen -W "${comp_ssh_hosts}" -- $cur))
    return 0
}
complete -F _complete_ssh_hosts ssh

function wgets() {
  local H='--header'
  wget $H='Accept-Language: en-us,en;q=0.5' $H='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' $H='Connection: keep-alive' -U ' Mozilla/5.0 (Windows NT 10.0; WOW64; rv:48.0) Gecko/20100101 Firefox/48.0' --referer=/ "$@";
}

extract () {
   if [ -f $1 ] ; then
       case $1 in
           *.tar.bz2)   tar xvfj $1    ;;
           *.tar.gz)    tar xvfz $1    ;;
           *.bz2)       bunzip2 $1     ;;
           *.rar)       unrar x $1     ;;
           *.gz)        gunzip $1      ;;
           *.tar)       tar xvf $1     ;;
           *.tbz2)      tar xvfj $1    ;;
           *.tgz)       tar xvfz $1    ;;
           *.zip)       unzip $1       ;;
           *.Z)         uncompress $1  ;;
           *.7z)        7z x $1        ;;
           *)           echo "don't know how to extract '$1'..." ;;
       esac
   else
       echo "'$1' is not a valid file!"
   fi
}