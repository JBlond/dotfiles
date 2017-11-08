# Alias definitions.
eval "`dircolors -b`"
alias ls='ls --color=auto --group-directories-first'
alias dir='ls --color=auto --format=vertical'

alias grep='grep --color=auto --exclude-dir="node_modules"'
alias fgrep='fgrep --color=auto --exclude-dir="node_modules"'
alias egrep='egrep --color=auto --exclude-dir="node_modules"'

#debian
#alias upgrade='sudo aptitude update && sudo aptitude dist-upgrade'
#updates are fetched via cron-apt
alias upgrade='sudo apt dist-upgrade'

# some more ls aliases
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
alias us="ls -la | grep ^- | awk '{print \$9}' | grep ^\\\."
alias nano='nano -wc'
alias ..='cd ..'
alias cd..='cd ..'
alias more='less'
alias ping5='ping -c 5'
alias dush='du . -sh'

alias lll="stat --format='%a %U %G %s %y %N' *"

alias :D="echo ツ"

alias fuck='sudo $(history -p \!\!)'

# docker stuff
alias docker='sudo docker'
alias docker-compose='sudo docker-compose'
alias docker-decompose="sudo docker stop $(sudo docker ps -a -q) && sudo docker rm $(sudo docker ps -a -q) && sudo docker rmi $(sudo docker images -a -q)"

dcomposer () {
    tty=
    tty -s && tty=--tty
    docker run \
        $tty \
        --interactive \
        --rm \
        --user $(id -u):$(id -g) \
        --volume /etc/passwd:/etc/passwd:ro \
        --volume /etc/group:/etc/group:ro \
        --volume $(pwd):/app \
        composer "$@"
}
