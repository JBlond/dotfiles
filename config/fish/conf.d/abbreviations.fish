abbr download "curl -LO "

abbr own 'sudo chown -R $USER:$USER'

abbr cls 'clear'

abbr ös 'ls'
abbr ll 'ls -lh'
abbr lla 'ls -lAh'
abbr la 'ls -A'
abbr lart 'ls -lhart'
abbr l 'ls -CF'
abbr lss 'ls -liSAh'
abbr l1 'ls -1'

abbr lll "stat --format='%a %U %G %s %y %N' * | column -t"
abbr lal "ls -a | awk '{print $NF}'"

abbr dfh 'df -kTh'
abbr dus 'du -hs * | sort -h'
abbr dush 'du . -sh'
abbr greedy 'du -hs * | sort -rh'

abbr vf 'cd'
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr cd.. 'cd ..'

abbr rmf 'rm -rf'

abbr gut 'git'
abbr gcl "git clone --recurse-submodules"
abbr gcma "git cma"
abbr gcmap "git cmap"
abbr gd "git diff"
abbr ggc "git gc"
abbr gib "git init --bare"
abbr gl "git lg"
abbr glc "git diff @~..@"
abbr gm "git checkout main"
abbr gp "git pull --progress --no-rebase"
abbr gpn "git pull --no-ff"
abbr gpo "git push origin"
abbr gr "git remote -v"
abbr gst "git status -sb"
abbr gsu "git submodule update --recursive --remote"

abbr docker-compose "docker compose"
abbr dssh "docker exec -it"
abbr dcu "docker compose up -d"
abbr dcuf "docker compose up -d && docker compose logs -f"
abbr dcd "docker compose down"
abbr dcp "docker compose pull"
abbr dcl "docker compose logs -f"
abbr dps "docker ps --format \"table {{ .Names }}\" -a"
abbr dsp "docker system prune -a"

abbr composer 'composer --ansi'

abbr more 'less'
abbr vom 'vim'
abbr svim 'sudo vim'

# display all rules #
abbr iptlist 'sudo /sbin/iptables -L -n -v --line-numbers'
abbr iptlistin 'sudo /sbin/iptables -L INPUT -n -v --line-numbers'
abbr iptlistout 'sudo /sbin/iptables -L OUTPUT -n -v --line-numbers'
abbr iptlistfw 'sudo /sbin/iptables -L FORWARD -n -v --line-numbers'
abbr iptuseage 'sudo iptables -L -nvx | grep -v " 0 DROP"'
abbr firewall iptlist
abbr ipt 'sudo /sbin/iptables'

abbr journalctl 'sudo journalctl'
abbr systemctl 'sudo systemctl'
