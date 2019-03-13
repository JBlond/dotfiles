if [[ "$OSTYPE" == "FreeBSD" ]]; then
	alias ls='ls -G'
else
	eval "`dircolors -b`"
	alias ls='ls --color=auto --group-directories-first'
fi

alias dir='ls --color=auto --format=vertical'

alias ös='ls'
alias ll='ls -lh'
alias lla='ls -lAh'
alias la='ls -A'
alias lart='ls -lhart'
alias l='ls -CF'
alias us="ls -la | grep ^- | awk '{print \$9}' | grep ^\\\."
alias lll="stat --format='%a %U %G %s %y %N' *"
alias lal="ls -a | awk '{print $NF}'"
