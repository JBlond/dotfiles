# install

```bash
git clone https://github.com/JBlond/dotfiles.git
cd dotfiles
./deploy.sh
```

## Linux

On Linux you can also use *make* to install it. Run `make` without any parameter to see all options.
On [Git for Windows SDK](https://github.com/git-for-windows/build-extra/releases/latest) use pacman to install make
`pacman -S make`

### make options
```bash
 make backup        take a backup of the original .bashrc
                    (it is saved as .bashrc.ORIGINAL)
                    you should run this once in the begining
                    otherwise you may overwrite the backup

 make cert          stop apache and updte let's encrypt

 make continuum     install tmux continuum plugin

 make install       run the deploy script
```
