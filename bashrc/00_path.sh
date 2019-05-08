#add sbin's to prompt
PATH="/sbin:/usr/local/sbin:$PATH"

# add composer bins to path if installed
if [ -d "$HOME/.composer/vendor/bin" ]; then
	PATH="$HOME/.composer/vendor/bin:$PATH"
fi

if [ -d "$HOME/.yarn/" ]; then
	PATH="$HOME/.yarn/bin:$PATH"
fi

if [ -f "$HOME/ansible/hosts" ]; then
	export ANSIBLE_INVENTORY=~/ansible/hosts
fi

if [ -d "$HOME/notes/bin" ]; then
	PATH="$HOME/notes/bin:$PATH"
fi

complete -d cd
