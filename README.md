# dotfiles

![shell2](assets/shell02.png)

I use my dotfiles on bash and fish shell from git for windows, debian bash and fish , ubuntu bash and fish. Works on OSX bash, too.

Using tmux on git for windows download the [Git for Windows SDK](https://github.com/git-for-windows/build-extra/releases/latest)
and run pacman.

```bash
pacman -S tmux fish
```

## install

[install README](install.md)

## bash

[bash functions](bash.md)

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

## git aliases and commands

[git](git.md)

[git aliases](git/aliases.ini#L2-L53)

![shell1](assets/shell01.png)

![shell3](assets/shell03.png)

### ssh / remote session

ssh://user@host:🏠

## Functions

- [goto](https://github.com/iridakos/goto)
- bash completion
- ssh completion  ssh example *TAB* reads the ~/.ssh/config file for host completion
- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) fancy diff for git ( and others)
- docker aliases + ssh into docker / docker exec completion. e.g. dssh example *TAB*
- git_functionspart for simplify git.  an = add next git file dn = diff next file
- git-prompt have a nice prompt inside git repos
- [git alias](git.md)

## Tmux

[tmux README](tmux.md) custom shortcuts and other good stuff

![shell4](assets/shell04.png)
![shell5](assets/vim-in-tmux.png)

## Vim

Vim has different Syntax highlighting themes. Can be changed using `CTRL` + `Y`

### hybrid reverse

![vim](assets/vim01.png)

### monokai

![vim](assets/vim02.png)
