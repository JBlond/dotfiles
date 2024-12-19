function hibernate --wraps='rundll32.exe powrprof.dll,SetSuspendState' --description 'alias hibernate=rundll32.exe powrprof.dll,SetSuspendState'
	rundll32.exe powrprof.dll,SetSuspendState $argv
end
