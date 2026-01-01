function show_path -d "list directories in path"
	for value in $PATH
		if test -d $value
			echo $value
		end
  end
end
