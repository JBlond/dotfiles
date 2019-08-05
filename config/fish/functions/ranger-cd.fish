function ranger-cd
	set tmpfile "/tmp/pwd-from-ranger"
	ranger --choosedir=$tmpfile $argv
	set rangerpwd (cat $tmpfile)
	if test "$PWD" != $rangerpwd
		cd $rangerpwd
	end
end