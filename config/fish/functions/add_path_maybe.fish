# Add a directory to the path, but only if it exists.

function add_path_maybe -d "Add a directory to the path, but only if it exists"
	# If the path exists...
	if test -d $argv[1]
		# ...and if it's not already in the PATH...
		if not contains $argv[1] $PATH
			# ...push it to the start of the path.
			set PATH $argv[1] $PATH
		end
	end
end
