function __ssh_agent_is_started -d "check if ssh agent is already started"
	# Do not clobber a forwaraded SSH agent socket.
	if begin; test -n "$SSH_AUTH_SOCK"; and test -e "$SSH_AUTH_SOCK"; end
		return 0
	end

	if begin; test -f $SSH_ENV; and test -z "$SSH_AGENT_PID"; end
		source $SSH_ENV > /dev/null
	end

	if begin; test -z "$SSH_AGENT_PID"; and test -z "$SSH_CONNECTION"; end
		return 1
	end

	ssh-add -l > /dev/null 2>&1
	if test $status -eq 2
		return 1
	end
end
