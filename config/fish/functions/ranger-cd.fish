function ranger-cd
	if not test -f /tmp/pwd-from-ranger
		touch /tmp/pwd-from-ranger
	end	
	set tmpfile "/tmp/pwd-from-ranger"
	ranger --choosedir=$tmpfile $argv
	set rangerpwd (cat $tmpfile)
	if test "$PWD" != $rangerpwd
		cd $rangerpwd
	end
end
