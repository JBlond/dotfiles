set -g fish_prompt_pwd_dir_length 30

# path
set PATH /sbin /usr/local/sbin $HOME/dotfiles/git/bin $PATH

# add composer bins to path if installed
if test -d $HOME/.composer/vendor/bin
	set PATH $HOME/.composer/vendor/bin $PATH
end

if test -d $HOME/.yarn/
	set PATH $HOME/.yarn/bin $PATH
end

if test -d $HOME/notes/bin/
	set PATH $HOME/notes/bin $PATH
end

if test -d $HOME/ranger
	alias ranger="$HOME/ranger/ranger.py"
end

# Enable aliases to be sudo’ed
alias sudo='sudo '

alias pleace="sudo"
alias please="sudo"

alias own='sudo chown -R $USER:$USER'


alias ls='ls --color=auto --group-directories-first'
alias dir='ls --color=auto --format=vertical'

alias cls='clear'

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
alias install='sudo apt install'

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
alias dontcare='echo ¯\\\_\(ツ\)_/¯'
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


set -x LESS_TERMCAP_mb (printf "\u001b[01;31m")
set -x LESS_TERMCAP_md (printf "\u001b[01;31m")
set -x LESS_TERMCAP_me (printf "\u001b[0m")
set -x LESS_TERMCAP_se (printf "\u001b[0m")
set -x LESS_TERMCAP_so (printf "\u001b[01;44;33m")
set -x LESS_TERMCAP_ue (printf "\u001b[0m")
set -x LESS_TERMCAP_us (printf "\u001b[01;32m")

set -Ux LS_COLORS 'rs=0:di=01;34:ln=01;36:mh=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.vob=01;35:*.wmv=01;35:*.asf=01;35:*.avi=01;35:*.flv=01;35:*.dl=01;35:*.xcf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.flac=00;36:*.m4a=00;36:*.mka=00;36:*.mp3=00;36:*.ogg=00;36:*.ra=00;36'
