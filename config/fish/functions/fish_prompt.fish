function _git_branch_name
	echo (command git name-rev --name-only HEAD 2>/dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
	echo (command git status -s --ignore-submodules=dirty 2>/dev/null)
end

function _is_ssh_session
	# Prüfe auf klassische SSH-Umgebungsvariablen
	if set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY
		return 0
	end
    set tty_name (tty)
    if string match -r '^/dev/pts/' $tty_name
        return 0
    end
	# Prüfe auf tmux mit SSH: Wenn tmux läuft, prüfe, ob die übergeordnete Shell SSH war
	if set -q TMUX
		# Versuche, die ursprüngliche SSH-Verbindung über die Umgebungsvariablen zu finden
		if string match -q '*ssh*' (ps -o cmd= -p (ps -o ppid= -p (ps -o ppid= -p (status pid))))
			return 0
		end
	end

	return 1
end


function fish_prompt
	set -l last_status $status
	set -l cyan (set_color -o cyan)
	set -l yellow (set_color -o yellow)
	set -l red (set_color -o red)
	set -l blue (set_color -o blue)
	set -l green (set_color -o green)
	set -l normal (set_color normal)

	if not set -q __fish_prompt_char
		switch (id -u)
			case 0
				set __fish_prompt_char '⚡⚡ '
			case '*'
				set __fish_prompt_char 'λ '
		end
	end

	if test $last_status = 0
		set status_indicator "$green✓ "
		set exit_code ""
	else
		set status_indicator "$red✗ "
		set exit_code (set_color -i a52a2a) "[" $last_status "]"
	end
	set -l cwd $blue(prompt_pwd)

	set -l branch_name (_git_branch_name)
	#echo 'branch name is ' + $branch_name
	if [ $branch_name ]

		if test $branch_name = 'master'
			set -l git_branch "master"
			set git_info \n"$normal $cyan(♆ $red$git_branch$cyan)$normal"
		else if test $branch_name = 'main'
			set -l git_branch "main"
			set git_info \n"$normal $cyan(♆ $red$git_branch$cyan)$normal"
		else
			set -l git_branch $branch_name
			set git_info \n"$normal $cyan(♆ $git_branch)$normal"
		end

		if [ (_is_git_dirty) ]
			set -l dirty "$yellow ✗"
			set git_info "$git_info$dirty"
		end
	end

	echo -n -s $status_indicator

	if _is_ssh_session
		echo $red'ssh://'$cyan(whoami)$green'@'(hostname) $cwd $git_info $exit_code $normal ' '
	else
		echo $cyan(whoami) $cwd $git_info $exit_code $normal ' '
	end
	# echo # To print an empty line
	# prompt character
	set_color ff0000
	echo -n $__fish_prompt_char
	set_color normal

end
