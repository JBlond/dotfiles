if test -d $HOME/ranger
	alias ranger="$HOME/ranger/ranger.py"
end

alias cursor='echo -ne "\e[3 q"'
# Enable aliases to be sudo’ed
alias sudo='sudo '

alias hibernate="rundll32.exe powrprof.dll,SetSuspendState"

alias journalctl='sudo journalctl'
alias systemctl='sudo systemctl'

alias grep='grep --color=auto --exclude-dir="node_modules"'
alias fgrep='fgrep --color=auto --exclude-dir="node_modules"'
alias egrep='egrep --color=auto --exclude-dir="node_modules"'
alias rns='grep -Rns $argv *'

alias shit="echo 💩"
alias :D="echo ツ"
alias dontcare='echo ¯\\\_\(ツ\)_/¯'
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'
alias shangdi="echo 上帝就是愛"

alias nano='nano -wc'

alias vless='/usr/share/vim/vim8*/macros/less.sh'
alias :e="vim"
# use vim alias to exit shell
alias :q="exit"
