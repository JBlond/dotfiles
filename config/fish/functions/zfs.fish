function zfs
	set real_zfs (command -v zfs)
	if test -z "$real_zfs"
		echo "Error: ZFS is not installed on this system" >&2
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
