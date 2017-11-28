# Alias definitions.
eval "`dircolors -b`"
alias ls='ls --color=auto --group-directories-first'
alias dir='ls --color=auto --format=vertical'

alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
alias us="ls -la | grep ^- | awk '{print \$9}' | grep ^\\\."
alias lll="stat --format='%a %U %G %s %y %N' *"

alias ..='cd ..'
alias cd..='cd ..'

alias grep='grep --color=auto --exclude-dir="node_modules"'
alias fgrep='fgrep --color=auto --exclude-dir="node_modules"'
alias egrep='egrep --color=auto --exclude-dir="node_modules"'

#debian
#alias upgrade='sudo aptitude update && sudo aptitude dist-upgrade'
#updates are fetched via cron-apt
alias update='sudo apt update'
alias upgrade='sudo apt dist-upgrade'

alias nano='nano -wc'
alias more='less'

alias ping5='ping -c 5'
alias flushdns="sudo /etc/init.d/dns-clean restart && echo DNS cache flushed"

alias dush='du . -sh'

alias :D="echo ツ"
alias dontcare='echo ¯\\_\(ツ\)_/¯'
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'

alias fuck='sudo $(history -p \!\!) && echo "( ︶︿︶)_╭∩╮"'
