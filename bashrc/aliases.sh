# Alias definitions.
eval "`dircolors -b`"
alias ls='ls --color=auto --group-directories-first'
alias dir='ls --color=auto --format=vertical'

alias ll='ls -lh'
alias lla='ls -lAh'
alias la='ls -A'
alias lart='ls -lhart'
alias l='ls -CF'
alias us="ls -la | grep ^- | awk '{print \$9}' | grep ^\\\."
alias lll="stat --format='%a %U %G %s %y %N' *"

alias dfh='df -kTh'
alias dus='du -hs * | sort -h'
alias dush='du . -sh'

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

alias bashrc='source ~/.bashrc'
alias dotfiles='cd ~/dotfiles'

alias nano='nano -wc'
alias more='less'

alias rmf='rm -rf'

alias ping5='ping -c 5'
alias flushdns="sudo /etc/init.d/dns-clean restart && echo DNS cache flushed"
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"

alias wttr='curl -L wttr.in/?lang=de'
alias :D="echo ツ"
alias dontcare='echo ¯\\_\(ツ\)_/¯'
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias own='sudo chown -R ${USER:=$(/usr/bin/id -run)}:$USER'
alias fuck='sudo $(history -p \!\!) && echo "( ︶︿︶)_╭∩╮"'

if [[ "$OSTYPE" == "msys" ]]; then
	alias apache='~/Apache24/bin/httpd.exe'
else
	alias apache='sudo /opt/apache2/bin/httpd'
fi
