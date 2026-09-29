function symlink --argument-names _from _to
	if test -z "$_from"; or test -z "$_to"
		echo "symlink: must provide from and to arguments" >&2
		return 1
	end

	set -l abs_to (realpath "$_to")

	if test -d "$_to"; and not test -d "$_from"
		set to "$abs_to/"(basename "$_from")
	else
		set to "$abs_to"
	end

	set -l from (realpath "$_from")

	ln -s "$from" "$to"
end
