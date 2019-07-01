function prompt_long_pwd --description 'Print the current working directory'
	echo $PWD | sed -e "s|^$HOME|~|" -e 's|^/private||'
end
