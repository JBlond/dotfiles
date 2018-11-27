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

[install](install.md)

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

## Tmux
[tmux](tmux.md)
