# dotfiles

I use my dotfiles on bash from git for windows, debian bash, ubuntu bash.

## bash
```
jblond@linux:~/dotfiles
(master)[▼2] ✓
λ
jblond@linux:~/dotfiles
(master)[▼2] ✓
λ git pull
jblond@linux:~/dotfiles
(master) ✓
jblond@linux:~/dotfiles
(master) 1⬤ 4Ξ 1✗ 1⚡⚡
λ git commit -a -m "my commit"
jblond@linux:~/dotfiles
(master)[▲1] ✓
λ git push
jblond@linux:~/dotfiles
(master) ✓
λ
jblond@linux:~/dotfiles
(master) ✓
λ ..
jblond@linux:~
λ

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
- `F4` Close window and its panes. The last window closes tmux, too.
- `F5` Reload config
- `F6` Toogle status bar on and off
- `F11` Toogle mouse on and off
- `F12` Turn off/on the parent tmux in nested tmux or for the use of a program like midnight commander (mc) that uses the F keys itself
- `CTRL + B` `|` Split window vertical
- `CTRL + B` `-` Split window horizontal
- `CTRL + B` `S` Toggle pane synchronization
- `CTRL + B` `Spacebar` Toggle between pane layouts
- `CTRL + B` `r` Reload config
- `CTRL + B` `$` Rename session
- `CTRL + B` `,` Rename window
- `CTRL + B` `z` Zoom into pane or window / zoom out
- `CTRL + B` `PageUp` or `PageDown` Scrolling
- `CTRL + B` `w` List sessions and windows
- `CTRL + B` `d` Detach from session
- `CTRL + B` `&` Close current window
- `CTRL + B` `q` Number all windows and panes
- `CTRL + B` `Crtl + v` paste

Included is
- Tmux Plugin Manager
- Tmux resurrect

Running Tmux for the first time press `CTRL + B` `I` to install the plugins.
- `CTRL + B` `CTRL + s` saves the current environment
- `CTRL + B` `CTRL + r` restores the previous saved environment

### Sharing Terminal Sessions Between Two Different Accounts
In the first terminal, start tmux where shared is the session name and shareds is the name of the socket:

`tmux -S /tmp/shareds new -s shared`

In the second terminal attach using that socket and session.

`tmux -S /tmp/shareds attach -t shared`

The decision to work read-only is made when the second user attaches to the session.
`tmux -S /tmp/shareds attach -t shared -r`

### Split in three equal panes

`CTRL + B` `|`
`CTRL + B` `|`
`CTRL + B` `:` `select-layout even-horizontal`

#### or 

`CTRL + B` `-`
`CTRL + B` `-`
`CTRL + B` `:` `select-layout even-vertical`
