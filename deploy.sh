#!/bin/bash
rm -f $HOME/.bash_logout
rm -f $HOME/.bashrc
rm -f $HOME/.gitconfig
rm -f $HOME/.minttyrc
rm -f $HOME/.nanorc
rm -f $HOME/.profile
rm -rf $HOME/.vimrc
rm -rf $HOME/.vim
cp -r ./.config ../
ln $HOME/dotfiles/.bash_logout $HOME/.bash_logout
ln $HOME/dotfiles/.bashrc $HOME/.bashrc
ln $HOME/dotfiles/git/.gitconfig $HOME/.gitconfig
ln $HOME/dotfiles/.minttyrc $HOME/.minttyrc
ln $HOME/dotfiles/.nanorc $HOME/.nanorc
ln $HOME/dotfiles/.profile $HOME/.profile
ln -s $HOME/dotfiles/vim $HOME/.vim
ln $HOME/dotfiles/.vimrc $HOME/.vimrc
ln $HOME/dotfiles/.tmux.conf $HOME/.tmux.conf
source ~/.bashrc
