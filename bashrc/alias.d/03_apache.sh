if [[ "$OSTYPE" == "msys" ]]; then
	alias apache='~/Apache24/bin/httpd.exe'
	alias hibernate="rundll32.exe powrprof.dll,SetSuspendState"
	alias ifconfig="ipconfig -all"
	alias lock="rundll32.exe user32.dll,LockWorkStation"
else
	alias apache='sudo /opt/apache2/bin/httpd'
fi
