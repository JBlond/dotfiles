set -g fish_prompt_pwd_dir_length 30

# Enable aliases to be sudo’ed
alias sudo='sudo '


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

alias mkdir='mkdir -p'

alias ..='cd ..'
alias cd..='cd ..'

alias rmf='rm -rf'

alias path='echo $PATH | tr ":" "\n"'

alias ga="git add"
alias gbr="git branch"
alias gcfg="git config --list"
alias gcl="git clone --recurse-submodules"
alias gcma="git cma"
alias gcmap="git cmap"
alias gco="git checkout"
alias gd="git diff"
alias gdiff="git diff"
alias gg="git branch -vv"
alias ggc="git gc"
alias gi="git init"
alias gib="git init --bare"
alias gitu="git cmapu"
alias gl="git lg"
alias glc="git diff @~..@"
alias gm="git checkout master"
alias gp="git pull --progress --no-rebase"
alias gpn="git pull --no-ff"
alias gpo="git push origin"
alias gr="git remote -v"
alias gst="git status -sb"
alias gsu="git submodule update --recursive --remote"

alias hibernate="rundll32.exe powrprof.dll,SetSuspendState"

alias vagrant="vagrant --color"
alias vm="vagrant ssh"

alias composer='composer --ansi'

alias update='sudo apt update'
alias list='sudo apt list --upgradable'
alias upgrade='sudo apt dist-upgrade'
alias autoremove='sudo apt autoremove'

alias journalctl='sudo journalctl'
alias systemctl='sudo systemctl'
alias sc='systemctl'

alias grep='grep --color=auto --exclude-dir="node_modules"'
alias fgrep='fgrep --color=auto --exclude-dir="node_modules"'
alias egrep='egrep --color=auto --exclude-dir="node_modules"'
alias rns='grep -Rins $1 *'

alias download="curl -LO "

alias shit="echo 💩"
alias :D="echo ツ"
alias dontcare='echo ¯\\_\(ツ\)_/¯'
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'
alias shangdi="echo 上帝就是愛"

# make me a password
alias genpasswd='echo `env LC_CTYPE=C tr -dc "a-zA-Z0-9-_\$\?" < /dev/urandom | head -c 20`'

alias nano='nano -wcz'
alias more='less'
alias svim='sudo vim'
alias vless='/usr/share/vim/vim8*/macros/less.sh'

# use vim alias to exit shell
alias :q="exit"

alias ipt='sudo /sbin/iptables'

# display all rules #
alias iptlist='sudo /sbin/iptables -L -n -v --line-numbers'
alias iptlistin='sudo /sbin/iptables -L INPUT -n -v --line-numbers'
alias iptlistout='sudo /sbin/iptables -L OUTPUT -n -v --line-numbers'
alias iptlistfw='sudo /sbin/iptables -L FORWARD -n -v --line-numbers'
alias iptuseage='sudo iptables -L -nvx | grep -v " 0 DROP"'
alias firewall=iptlist
