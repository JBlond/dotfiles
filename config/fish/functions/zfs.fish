function zfs
	if type -q zfs
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
end