find_git_dirty () {
	if [[ -z $(__git_ps1) ]]; then
		exit
	fi
	gitstatus=$(git status --porcelain | sed s/^.// | cut -d' ' -f1)
	for line in $gitstatus; do
		if [ "$line" = "D" ]; then
			printf " ✗"
		elif [ "$line" = "M" ]; then
			printf " \e[41m✗\033[0m";
		fi
	done
	if [ -z "$gitstatus" ]; then
		printf " \e[32m✓"
	fi
	modifiedfiles=$(git status --porcelain | grep "^M" | cut -c 4-)
	for line1 in $modifiedfiles; do
		printf " \e[41m✗";
	done
	addedfiles=$(git status --porcelain | grep "^A" | cut -c 4-)
	for line2 in $addedfiles; do
		printf " Ξ"
	done
	untracked=$(git ls-files --others --exclude-standard)
	for line3 in $untracked; do
		printf " 🙈"
	done
}

find_git_commit_diff () {
  if [[ ! -z $(__git_ps1) ]]; then
    commit_diff=$(git for-each-ref --format="%(push:track)" refs/heads)
    commit_diff=${commit_diff//ahead\ /\+}
    commit_diff=${commit_diff//behind\ /\-}
    echo $commit_diff
  fi
}