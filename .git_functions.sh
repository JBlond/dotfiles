find_git_dirty () {
	if [[ -z $(__git_ps1) ]]; then
		exit
	fi
	local clean="clean"

	gitstatus=$(git status --porcelain | sed s/^.// | cut -d' ' -f1)
	deletedfiles_number=0
	modifiedfiles_number=0
	for line in $gitstatus; do
		if [ "$line" = "D" ]; then
			let "deletedfiles_number++"
			clean="dirty"
		elif [ "$line" = "M" ]; then
			let "modifiedfiles_number++"
			clean="dirty"
		fi
	done
	if [ $deletedfiles_number -gt 0 ]; then
		printf " $deletedfiles_number""x✗\033[0m"
	fi
	if [ $modifiedfiles_number -gt 0 ]; then
		printf " \033[0m$modifiedfiles_number""x\e[41m✗\033[0m"
	fi

	addedfiles_number=0
	addedfiles=$(git status --porcelain | grep "^A" | cut -c 4-)
	for line2 in $addedfiles; do
		let "addedfiles_number++"
		clean="dirty"
	done
	if [ $addedfiles_number -gt 0 ]; then
		printf " $addedfiles_number""xΞ"
	fi

	untracked_number=0
	untracked=$(git ls-files --others --exclude-standard)
	for line3 in $untracked; do
		let "untracked_number++"
		clean="dirty";
	done
	if [ $untracked_number -gt 0 ]; then
		printf " $untracked_number""x🙈"
	fi
	
	if [[ -z "$gitstatus" && "$clean" == "clean" ]]; then
		printf " \e[32m✓"
	fi
}

find_git_commit_diff () {
  if [[ ! -z $(__git_ps1) ]]; then
    commit_diff=$(git for-each-ref --format="%(push:track)" refs/heads)
    commit_diff=${commit_diff//ahead\ /\+}
    commit_diff=${commit_diff//behind\ /\-}
    echo $commit_diff
  fi
}