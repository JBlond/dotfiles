#!/bin/bash
rm -f $HOME/.bash_logout
rm -f $HOME/.bashrc
rm -f $HOME/.gitconfig
rm -f $HOME/.nanorc
rm -f $HOME/.profile
rm -rf $HOME/.vim

rm -f $HOME/.hyper.js
if [[ "$OSTYPE" != "msys" ]]; then
	rm -f $HOME/.tmux.conf
	cp -r ./.config ../
	ln $HOME/dotfiles/home/tmux.conf $HOME/.tmux.conf
fi	
ln $HOME/dotfiles/home/bash_logout $HOME/.bash_logout
ln $HOME/dotfiles/home/bashrc $HOME/.bashrc
ln $HOME/dotfiles/git/gitconfig $HOME/.gitconfig
ln $HOME/dotfiles/home/nanorc $HOME/.nanorc
ln $HOME/dotfiles/home/profile $HOME/.profile
ln $HOME/dotfiles/home/hyper.js $HOME/.hyper.js
ln -s $HOME/dotfiles/vim $HOME/.vim
if [[ "$OSTYPE" == "msys" ]]; then
	rm -f $HOME/.minttyrc
	ln $HOME/dotfiles/home/minttyrc $HOME/.minttyrc
fi	
source ~/.bashrc
