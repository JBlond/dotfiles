function mkill --description 'Always kill the process by PID'
	if test (count $argv) -eq 0
		echo "mkill: PID fehlt" >&2
		return 1
	end
	switch (uname -o)
		case Msys
			taskkill /F /PID $argv[1]
		case "*"
			kill -9 $argv[1]
	end
	echo "( ︶︿︶)_╭∩╮"
end
