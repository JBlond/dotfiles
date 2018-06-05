#!/bin/bash
rm -f $HOME/.bash_logout
rm -f $HOME/.bashrc
rm -f $HOME/.gitconfig
rm -f $HOME/.nanorc
rm -f $HOME/.profile
rm -rf $HOME/.vim
if [[ "$OSTYPE" != "msys" ]]; then
	rm -f $HOME/.tmux.conf
	cp -r ./config ../.config
	ln $HOME/dotfiles/home/tmux.conf $HOME/.tmux.conf
fi	
ln $HOME/dotfiles/home/bash_logout $HOME/.bash_logout
ln $HOME/dotfiles/home/bashrc $HOME/.bashrc
ln $HOME/dotfiles/git/gitconfig $HOME/.gitconfig
ln $HOME/dotfiles/home/nanorc $HOME/.nanorc
ln $HOME/dotfiles/home/profile $HOME/.profile
ln -s $HOME/dotfiles/vim $HOME/.vim
if [[ "$OSTYPE" == "msys" ]]; then
	rm -f $HOME/.minttyrc
	ln $HOME/dotfiles/home/minttyrc $HOME/.minttyrc
fi	
source ~/.bashrc

while true;
do
	read -r -p "Yes or no? " response   
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
		rm -f $HOME/.zshrc
		rm -f $HOME/.babunrc
		ln $HOME/dotfiles/babun/zshrc $HOME/.zshrc
		ln $HOME/dotfiles/babun/babunrc $HOME/.babunrc
	else
		exit 0
	fi
done
