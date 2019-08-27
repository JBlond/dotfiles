#!/bin/bash
rm -f $HOME/.bash_logout
rm -f $HOME/.bashrc
rm -f $HOME/.gitconfig
rm -f $HOME/.nanorc
rm -f $HOME/.profile
rm -f $HOME/.inputrc
rm -rf $HOME/.vim
rm -f $HOME/.tmux.conf
cp -r ./config/fish ~/.config/
if [[ "$OSTYPE" != "msys" ]]; then
	cp -r ./config/htop ~/.config/
	cp -r ./config/mc ~/.config/
fi
ln $HOME/dotfiles/home/tmux.conf $HOME/.tmux.conf
ln $HOME/dotfiles/home/bash_logout $HOME/.bash_logout
ln $HOME/dotfiles/home/bashrc $HOME/.bashrc
ln $HOME/dotfiles/git/gitconfig $HOME/.gitconfig
ln $HOME/dotfiles/home/nanorc $HOME/.nanorc
ln $HOME/dotfiles/home/profile $HOME/.profile
ln $HOME/dotfiles/home/inputrc $HOME/.inputrc
ln -s $HOME/dotfiles/vim $HOME/.vim
if [[ "$OSTYPE" == "msys" ]]; then
	$HOME/config/minttyrc/config
	ln $HOME/dotfiles/home/minttyrc $HOME/.config/minttyrc/config
fi

if [[ ! -d ~/.tmux/plugins/tpm ]]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

source ~/.bashrc
