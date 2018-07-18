# Alias definitions.
eval "`dircolors -b`"
alias ls='ls --color=auto --group-directories-first'
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

alias dfh='df -kTh'
alias dus='du -hs * | sort -h'
alias dush='du . -sh'

alias ..='cd ..'
alias cd..='cd ..'

alias grep='grep --color=auto --exclude-dir="node_modules"'
alias fgrep='fgrep --color=auto --exclude-dir="node_modules"'
alias egrep='egrep --color=auto --exclude-dir="node_modules"'

#debian
alias update='sudo apt update'
alias list='sudo apt list --upgradable'
alias upgrade='sudo apt dist-upgrade'

alias bashrc='source ~/.bashrc'
alias dotfiles='cd ~/dotfiles'

alias nano='nano -wc'
alias more='less'

alias rmf='rm -rf'

alias path='echo $PATH | tr ":" "\n"'

alias ping5='ping -c 5'
alias flushdns="sudo /etc/init.d/dns-clean restart && echo DNS cache flushed"
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"

alias mssh="mosh"

alias wttr='curl -L wttr.in/?lang=de'

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias download="curl -LO "

alias own='sudo chown -R ${USER:=$(/usr/bin/id -run)}:$USER'
alias fuck='sudo $(history -p \!\!) && echo "( ︶︿︶)_╭∩╮"'
alias shit="echo 💩"
alias :D="echo ツ"
alias dontcare='echo ¯\\_\(ツ\)_/¯'
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'
alias shangdi="echo 上帝就是愛"

# use vim alias to exit shell
alias :q="exit"

if [[ "$OSTYPE" == "msys" ]]; then
	alias apache='~/Apache24/bin/httpd.exe'
	alias ifconfig="ipconfig -all"
	alias lock="rundll32.exe user32.dll,LockWorkStation"
else
	alias apache='sudo /opt/apache2/bin/httpd'
fi

#############
# git aliases
alias g="git"

source /usr/share/bash-completion/completions/git
complete -o default -o nospace -F _git g

alias gcl="git clone"
alias gcma="git cma"
alias gcmap="git cmap"
alias gco="git checkout"
alias gd="git diff"
alias gdiff="git diff"
alias ggc="git gc"
alias gh='cd "$(git rev-parse --show-toplevel)"'
alias glc="git diff @~..@"
alias glg="git lg"
alias gst="git status -sb"
alias gsu="git submodule update --recursive --remote"
