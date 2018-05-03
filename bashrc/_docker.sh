# docker stuff
if [ -x "/usr/bin/docker" ]; then
	alias docker-restart='sudo /etc/init.d/docker restart'
	alias docker-socket='sudo chmod 777 /var/run/docker.sock'
	alias docker='sudo docker'
	alias docker-compose='sudo docker-compose'
	alias docker-decompose="sudo docker stop $(sudo docker ps -a -q) && sudo docker rm $(sudo docker ps -a -q) && sudo docker rmi $(sudo docker images -a -q)"
	
	dssh() {
		sudo docker exec -it $1 bash
	}

	#compdef docker-ssh
	_docker_ssh() {
		local cur prev opts
		COMPREPLY=()
		cur="${COMP_WORDS[COMP_CWORD]}"
		prev="${COMP_WORDS[COMP_CWORD-1]}"
		opts=$(docker ps --filter status=running --format='{{.Names}}')
		if [[ ${cur} == * ]] ; then
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		fi
	}

	complete -F _docker_ssh dssh
fi
