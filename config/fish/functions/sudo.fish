function sudo --description 'alias sudo=sudo '
	set real_sudo (command -v sudo)
	if test -z "$real_sudo"
		echo "Error: sudo is not installed on this system" >&2
		return 1
	end
	# Enable aliases to be sudo’ed
	command sudo  $argv
end
