function fish_greeting --description 'Print the shell greeting'
	set -l c_n (set_color normal)
	set -l c_w (set_color cyan)

	set -l dt (string split '|' -- (date '+%T|%Z|%F'))
	set -l tty_name (tty | string replace -r '.*tty(.*)' '$1')

	set -l location (printf "%sWelcome to %s%s%s" $c_n $c_w $hostname $c_n)
	set -l system (printf "%sRunning %s%s%s on %s%s%s" $c_n $c_w (uname -mrs) $c_n $c_w $tty_name $c_n)
	set -l datetime (printf "%sIt is %s%s%s (%s) on %s%s%s" $c_n $c_w $dt[1] $c_n $dt[2] $c_w $dt[3] $c_n)

	printf "\n  %s\n  %s\n  %s\n\n" $location $system $datetime
end
