find_git_dirty () {
	if [[ -z $(__git_ps1) ]]; then
		exit
	fi
	local symbol_added="\e[33mΞ"
	local symbol_clean="\e[32m✓"
	local symbol_deleted="\e[41m✗\033[0m"
	local symbol_modified="\e[36m●\033[0m"
	local symbol_renamed="\e[0;45mᏪ\033[0m"
	local symbol_untracked="🙈"
	local clean="clean"

	gitstatus=$(git status --porcelain | sed s/^.// | cut -d' ' -f1)
	modifiedfiles_number=0
	deletedfiles_number=0
	
	for line in $gitstatus; do
		# linux
		if [ "$line" = "D" ]; then 
            let "deletedfiles_number++" 
            clean="dirty" 
        elif [ "$line" = "M" ]; then 
			let "modifiedfiles_number++"
			clean="dirty"
		fi
	done
	if [ $modifiedfiles_number -gt 0 ]; then
		printf " \033[0m$modifiedfiles_number""$symbol_modified"
	fi

	# git for windows
	deletedfiles=$(git status --porcelain | grep "^D" | cut -c 4-)
	for line2 in $deletedfiles; do
		let "deletedfiles_number++"
		clean="dirty"
	done
	if [ $deletedfiles_number -gt 0 ]; then
		printf " $deletedfiles_number""$symbol_deleted"
	fi

	addedfiles_number=0
	addedfiles=$(git status --porcelain | grep "^A" | cut -c 4-)
	for line2 in $addedfiles; do
		let "addedfiles_number++"
		clean="dirty"
	done
	if [ $addedfiles_number -gt 0 ]; then
		printf " $addedfiles_number""$symbol_added"
	fi

	renamedfiles_number=0
	renamedfiles=$(git status --porcelain | grep "^R" | cut -c 1)
	for renamed in $renamedfiles; do
		let "renamedfiles_number++"
		clean="dirty"
	done
	if [ $renamedfiles_number -gt 0 ]; then
		printf " $renamedfiles_number""$symbol_renamed"
	fi

	untracked_number=0
	untracked=$(git ls-files --others --exclude-standard)
	for line3 in $untracked; do
		let "untracked_number++"
		clean="dirty";
	done
	if [ $untracked_number -gt 0 ]; then
		printf " $untracked_number""$symbol_untracked"
	fi
	
	if [[ -z "$gitstatus" && "$clean" == "clean" ]]; then
		printf " $symbol_clean"
	fi
}

find_git_commit_diff () {
	if [[ ! -z $(__git_ps1) ]]; then
		commit_diff=$(git for-each-ref --format="%(push:track)" refs/heads)
		commit_diff=${commit_diff//ahead\ /\▲}
		commit_diff=${commit_diff//behind\ /\▼}
		echo $commit_diff
	fi
}

# next function are from https://github.com/arialdomartini/git-dashboard

diff-next() {
	git status --short --branch | grep '^.[DM\?]' | head -1 | awk '$1 ~ /[MD]/ {print $2} $1 ~ /\?/ {print "/dev/null " $2}' | xargs git diff --
}

dn() {
	diff-next
}

add-next() {
	git status --short --branch | grep '^.[DM\?]' | head -1 | awk '$1 ~ /[M?]/ {print "add " $2} $1 ~ /D/ {print "rm " $2}' | xargs git
}

an() {
	add-next
}
