function grep --description 'alias grep=grep --color=auto --exclude-dir="node_modules"'
	command grep --color=auto --exclude-dir="node_modules" $argv
end
