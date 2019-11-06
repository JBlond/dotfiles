function gh --description 'goto to git repo top folder'
	set -l target (git rev-parse --show-toplevel | string replace 'C:' '/c')
    cd "$target"
end
