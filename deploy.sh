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
ln $HOME/dotfiles/home/bash_logout $HOME/.bash_logout
ln $HOME/dotfiles/home/bashrc $HOME/.bashrc
ln $HOME/dotfiles/git/gitconfig $HOME/.gitconfig
ln $HOME/dotfiles/home/nanorc $HOME/.nanorc
ln $HOME/dotfiles/home/profile $HOME/.profile
ln $HOME/dotfiles/home/inputrc $HOME/.inputrc
ln -s $HOME/dotfiles/vim $HOME/.vim
if [[ "$OSTYPE" == "msys" ]]; then
	rm -rf $HOME/.config/mintty/config
	mkdir -p $HOME/.config/mintty/
	ln $HOME/dotfiles/config/mintty/config $HOME/.config/mintty/config
	ln $HOME/dotfiles/home/tmux.win.conf $HOME/.tmux.conf
else
	ln $HOME/dotfiles/home/tmux.linux.conf $HOME/.tmux.conf
fi

source ~/.bashrc
