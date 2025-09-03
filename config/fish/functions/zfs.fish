function zfs
	if not type -q zfs
		echo "Fehler: ZFS ist auf diesem System nicht installiert." >&2
		return 1
	end
	switch $argv[1]
		case destory
			set argv[1] destroy
		case ls
			set argv[1] list
			set argv[2] -t
			set argv[3] snapshot
	end
	command zfs $argv
end
