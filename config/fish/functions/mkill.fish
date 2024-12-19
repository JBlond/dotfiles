function mkill --description 'Always kill the process by PID'
	switch (uname -o)
		case Msys
			taskkill /F /PID $1
		case "*"
			kill -9 $1
	end
	echo "( ︶︿︶)_╭∩╮"
end
