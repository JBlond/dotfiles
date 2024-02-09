# fish functions

## functions

- `add_path_maybe <path>` Add a directory to the path variable, but only if it exists
- `fishy` Print a colored ascii version of the fish logo
- `please` Execute command with sudo in a nicer way
- `Fuck` Execute last command with sudo
- `gh` goto to git repo top folder
- `goto` A fish shell utility to quickly navigate to aliased directories supporting tab-completion
- `ranger-cd` change directory with ranger
- `symlink <from> <to>` create a symlink

## abbreviations

- `..` cd ..
- `ös` ls
- `autoremove` sudo apt autoremove
- `cd..` cd ..
- `cls` clear
- `composer` composer --ansi
- `composer2` composer2 --ansi
- `dfh` df -h
- `download` curl -LO `<url>`
- `dus` du -hs * | sort -h
- `dush` du . -sh
- `firewall` iptlist
- `gcl` git clone --recurse-submodules
- `gcma` git cma
- `gcmap` git cmap
- `gd` git diff
- `ggc` git gc
- `gib` git init --bare
- `gl` git lg
- `glc` git diff @~..@
- `gm` git checkout main
- `gp` git pull --progress --no-rebase
- `gpn` git pull --no-ff
- `gpo` git push origin
- `gr` git remote -v
- `greedy` du -hs * | sort -rh
- `gst` git status -sb
- `gsu` git submodule update --recursive --remote
- `install` sudo apt install
- `ipt` iptables
- `iptlist` sudo /sbin/iptables -L -n -v --line-numbers
- `iptlistfw` sudo /sbin/iptables -L FORWARD -n -v --line-numbers
- `iptlistin` sudo /sbin/iptables -L INPUT -n -v --line-numbers
- `iptlistout` sudo /sbin/iptables -L OUTPUT -n -v --line-numbers
- `iptuseage` sudo iptables -L -nvx | grep -v " 0 DROP"
- `journalctl` sudo journalctl
- `l` ls -CF
- `la` ls -A
- `lal` ls -a | awk '{print $NF}'
- `lart` ls -lhart
- `list` sudo apt list --upgradable
- `ll` ls -lh
- `lla` ls -lAh
- `lll` stat --format='%a %U %G %s %y %N' *
- `more` less
- `own` sudo chown -R $USER:$USER
- `rmf` rm -rf
- `sc` systemctl
- `svim` sudo svim
- `systemctl` sudo systemctl
- `update` sudo apt update
- `upgrade` sudo apt dist-upgrade
