if [ -z ${TMUX} ]; then
	if [[ "$3" = true || "${SSH_CLIENT}" || "${SSH_TTY}" || ${EUID} = 0 ]]; then
		tmux attach || tmux
	fi
fi
