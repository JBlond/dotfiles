# Alias definitions.

source ~/dotfiles/bashrc/alias.d/00_sudo.sh
source ~/dotfiles/bashrc/alias.d/01_ls.sh
source ~/dotfiles/bashrc/alias.d/02_git.sh

if [ -d "$HOME/ranger" ]; then
	alias ranger="$HOME/ranger/ranger.py"
fi

alias ?='man' #haha

alias dfh='df -kTh'
alias dus='du -hs * | sort -h'
alias dush='du . -sh'

alias mkdir='mkdir -p'

alias ..='cd ..'
alias cd..='cd ..'

alias grep='grep --color=auto --exclude-dir="node_modules"'
alias fgrep='fgrep --color=auto --exclude-dir="node_modules"'
alias egrep='egrep --color=auto --exclude-dir="node_modules"'

#debian
alias update='sudo apt update'
alias list='sudo apt list --upgradable'
alias upgrade='sudo apt dist-upgrade'
alias journalctl='sudo journalctl'
alias systemctl='sudo systemctl'
alias sc='systemctl'

alias own='sudo chown -R ${USER:=$(/usr/bin/id -run)}:$USER'

alias bashrc='source ~/.bashrc'
alias dotfiles='cd ~/dotfiles'

alias nano='nano -wcz'
alias more='less'
alias svim='sudo vim'

alias rmf='rm -rf'

alias path='echo $PATH | tr ":" "\n"'

alias ping5='ping -c 5'
alias flushdns="sudo /etc/init.d/dns-clean restart && echo DNS cache flushed"
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"

alias mssh="mosh"

alias wttr='curl -L wttr.in/?lang=de'

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias download="curl -LO "

alias shit="echo 💩"
alias :D="echo ツ"
alias dontcare='echo ¯\\_\(ツ\)_/¯'
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'
alias shangdi="echo 上帝就是愛"

# make me a password
alias genpasswd='echo `env LC_CTYPE=C tr -dc "a-zA-Z0-9-_\$\?" < /dev/urandom | head -c 20`'

# use vim alias to exit shell
alias :q="exit"

if [[ "$OSTYPE" == "msys" ]]; then
	alias apache='~/Apache24/bin/httpd.exe'
	alias hibernate="rundll32.exe powrprof.dll,SetSuspendState"
	alias ifconfig="ipconfig -all"
	alias lock="rundll32.exe user32.dll,LockWorkStation"
else
	alias apache='sudo /opt/apache2/bin/httpd'

	# A less excessive, yet still very, very useful current-user-focused ps command.
	if [ -x /bin/ps ]; then
		alias pss='/bin/ps -faxc -U $UID -o pid,uid,gid,pcpu,pmem,stat,comm'
	fi
fi

# Get and display the distribution type. (original base first)
if [ -f /etc/os-release -a -r /etc/os-release ]; then
	alias distro='\
		while read -a X; do
			if [[ "${X[0]}" == ID_LIKE=* ]]; then
				echo "${X[0]/*=}"; break
			elif [[ "${X[0]}" == ID=* ]]; then
				echo "${X[0]/*=}"; break
			fi
		done < /etc/os-release
	'
fi

alias cls='clear && tput reset'

# php
alias composer='composer --ansi'

# tmux
alias tvo="tmux new vim"
alias tov="tmux new vim"
alias tm="tmux a -t main || tmux new -s main"

#vagrant
alias vagrant="vagrant --color"
