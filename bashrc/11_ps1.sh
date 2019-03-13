__has_parent_dir () {
	# Utility function so we can test for things like .git/.hg without firing up a
	# separate process
	test -d "$1" && return 0;

	current="."
	while [ ! "$current" -ef "$current/.." ]; do
		if [ -d "$current/$1" ]; then
			return 0;
		fi
		current="$current/..";
	done

	return 1;
}

__vcs_name() {
	if __has_parent_dir ".git"; then
		echo "$(__git_ps1 '\n(%s)')";
	fi
}

set_prompt () {
	local last_command=$?  # Must come first!
	PS1=""
	# Add a bright white exit status for the last command
	# If it was successful, print a green check mark. Otherwise, print a red X.
	if [[ $last_command == 0 ]]; then
		PS1+='\[\e[01;32m\]✓ '
	else
		PS1+='\[\e[01;31m\]✗ '
	fi

	# set variable identifying the chroot you work in (used in the prompt below)
	if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
		debian_chroot=$(cat /etc/debian_chroot)
	fi

	bold=$(tput bold)
	normal=$(tput sgr0)

	where=$PWD
	home=$HOME
	work="$home/work"
	dotfiles="$HOME/dotfiles"
	where="${where/$work/🏢}"
	where="${where/$dotfiles/🏠/⬤}"
	where="${where/$home/🏠}"

	# show that this is a ssh session
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		PS1+='\[\033[1;31m\]ssh://'
	fi

	# display root user in red
	if [ $(id -u) -eq 0 ]; then
		PS1+='${debian_chroot:+($debian_chroot)}\[\033[1;31m\]\u\[\033[1;33m\]⚡⚡'
	else
		PS1+='${debian_chroot:+($debian_chroot)}\[\033[1;36m\]\u'
	fi

	# show host name only on remote connection
	if [[ "$3" = true || "${SSH_CLIENT}" || "${SSH_TTY}" || ${EUID} = 0 ]]; then
		PS1+='\[\033[01;32m\]@\h\[\033[00m\]'
	fi
	PS1+=':\[\033[01;34m\]$where\[\033[00m\]'
	if [ ! -w "$PWD" ]; then
		# ⛔ ⊘
		PS1+='\[\033[1;31m\]⛔'
	fi
	PS1+='\[\033[36m\]'
	PS1+='`__vcs_name`'
	if [[ "$OSTYPE" == "linux-gnu" ]]; then
		# very slow on cygwin and msys
		PS1+='`find_git_commit_diff`'
		PS1+='\[\033[1m\033[33m\]`find_git_dirty`'
	fi

	PS1+="\[\033[0;31m\]\n${bold}λ${normal}\[\033[0m\] "

	# have pwd in the title on term
	case $TERM in
		xterm*)
			echo -en "\033]0;${PWD}\007"
			;;
		*)
	esac

	PS2="\[\e[33m\]→ \e[0m"
}
PROMPT_COMMAND='set_prompt'
