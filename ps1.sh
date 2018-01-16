# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

bold=$(tput bold)
normal=$(tput sgr0)

if [ $(id -u) -eq 0 ];
then
	PS1='${debian_chroot:+($debian_chroot)}\[\033[1;31m\]\u\[\033[1;33m\]⚡⚡\[\033[01;32m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
else
	PS1='${debian_chroot:+($debian_chroot)}\[\033[1;36m\]\u\[\033[01;32m\]@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
fi
PS1="$PS1"'\[\033[36m\]'
PS1="$PS1"'`__git_ps1`'
# commenting out the next two lines will increase the speed inside a repo alot
PS1="$PS1"'`find_git_commit_diff`'
PS1="$PS1"'\[\033[1m\033[33m\]`find_git_dirty`'
PS1="$PS1""\[\033[0;31m\]\n${bold}⽕${normal}\[\033[0m\] "
