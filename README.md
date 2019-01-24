# dotfiles

I use my dotfiles on bash from git for windows, debian bash, ubuntu bash.

## bash

```BASH
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

![shell1](assets/shell01.png)

![shell2](assets/shell02.png)

![shell3](assets/shell03.png)

### ssh / remote session

ssh://user@host:🏠

## install

[install](install.md)

## Functions

- [goto](https://github.com/iridakos/goto)
- bash completion
- ssh completion  ssh example *TAB* reads the ~/.ssh/config file for host completion
- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) fancy diff for git ( and others)
- docker aliases + ssh into docker / docker exec completion. e.g. dssh example *TAB*
- git_functionspart for simplify git.  an = add next git file dn = diff next file
- git-prompt have a nice prompt inside git repos
- git aliases

## Tmux

[tmux](tmux.md)

![shell4](assets/shell04.png)
