# dotfiles

I use my dotfiles on bash from git for windows, debian bash, ubuntu bash.

## bash
```
jblond@linux:~/dotfiles
(master)[▼2] ✓
⽕ 
jblond@linux:~/dotfiles
(master)[▼2] ✓
⽕ git pull
jblond@linux:~/dotfiles
(master) ✓
jblond@linux:~/dotfiles
(master) 1⬤ 4Ξ 1✗ 1⚡⚡
⽕ git commit -a -m "my commit" 
jblond@linux:~/dotfiles
(master)[▲1] ✓
⽕ git push
jblond@linux:~/dotfiles
(master) ✓
⽕
jblond@linux:~/dotfiles
(master) ✓
⽕ ..
jblond@linux:~
⽕ 

```

- ✓ = repo is clean
- n⚡⚡  = n untracked files
- nΞ = n added files
- n⬤ = n modified files
- nᏪ = n renamed files
- n✗ = n deleted files
- [▲n] = n steps ahead of remote
- [▼n] = n steps behind remote

### ssh / remote session
ssh://user@host:🏠
 
## install

```bash
git clone https://github.com/JBlond/dotfiles.git
cd dotfiles
./deploy.sh
```

### Linux

On Linux you can also use *make* to install it. Run *make* without any parameter to see all options.

## scripts

- aliases.sh a bunch from my favorite bash aliases including fuck command if I forgot to type *sudo* infront of a command
- bash_completion.sh execute all bash completion available default from the system
- complete_ssh_hosts.sh ssh example *TAB* reads the ~/.ssh/config file for host completion
- deploy.sh deploy these files
- diff-so-fancy fancy diff for git ( and others)
- _docker.sh docker aliases + ssh into docker / docker exec completion. e.g. dssh example *TAB*
- functions.sh wgets wget with Firefox header. extract for many archive formats
- git_functions.sh part for simplify git.  an = add next git file dn = diff next file
- git-prompt.sh have a nice prompt inside git repos

## tmux
With this tmux config you can use nested sessions.

### keys
- `F1` new window
- `F2` next window
- `F3` previous window
- `F11` toogle mouse on and off
- `F12` Turn off/on the parent tmux in nested tmux. 
- `CTRL + B` `|` split window vertical
- `CTRL + B` `-` split window horizontal
- `CTRL + B` `S` Toggle pane synchronization
- `CTRL + B` `R` Reload condig
- `CTRL + B` `$` rename session
- `CTRL + B` `,` rename window
