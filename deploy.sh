#!/bin/bash
cp -r ./.config ../
ln $HOME/dotfiles/.bash_logout $HOME/.bash_logout
ln $HOME/dotfiles/.bashrc $HOME/.bashrc
ln $HOME/dotfiles/.gitconfig $HOME/.gitconfig
ln $HOME/dotfiles/.git-prompt.sh $HOME/.git-prompt.sh
ln $HOME/dotfiles/.minttyrc $HOME/.minttyrc
ln $HOME/dotfiles/.nanorc $HOME/.nanorc
ln $HOME/dotfiles/.profile $HOME/.profile
ln $HOME/dotfiles/.vimrc $HOME/.vimrc
source ~/.bashrc
