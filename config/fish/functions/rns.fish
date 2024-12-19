function rns --wraps='grep -Rns $argv *' --description 'alias rns=grep -Rns $argv *'
	grep -Rns $argv * $argv
end
