find_git_dirty () {

	if [[ -z $(__git_ps1) ]]; then
		exit
	fi

	#do not run in a bare repo
	if [[ $(git rev-parse --is-bare-repository ) = "true" ]]; then
		exit
	fi

	#dot not run in git dir
	if [[ $(git rev-parse --is-inside-git-dir) = "true" ]]; then
		exit
	fi

	local symbol_added="\e[33mΞ"
	local symbol_clean="\e[32m✓"
	local symbol_deleted="\e[41m✗\033[0m"
	local symbol_modified="\e[36m⬤\033[0m"
	local symbol_renamed="\e[0;45mᏪ\033[0m"
	local symbol_untracked="⚡⚡"
	local clean="clean"

	gitstatus="$(git status --porcelain)"
	addedfiles_number=0
	deletedfiles_number=0
	modifiedfiles_number=0
	renamedfiles_number=0
	untracked_number=0

	for line in $gitstatus; do
		# linux
		if [[ $line =~ ^D ]]; then
			let "deletedfiles_number++"
			clean="dirty"
		elif  [[ $line =~ ^M ]]; then
			let "modifiedfiles_number++"
			clean="dirty"
		elif [[ $line =~ ^A ]]; then
			let "addedfiles_number++"
			clean="dirty"
		elif [[ $line =~ ^R ]]; then
			let "renamedfiles_number++"
			clean="dirty"
		elif [[ $line =~ ^\?\? ]]; then
			let "untracked_number++"
			clean="dirty"
		fi
	done

	if [ $modifiedfiles_number -gt 0 ]; then
		printf " \033[0m$modifiedfiles_number""$symbol_modified"
	fi

	if [ $deletedfiles_number -gt 0 ]; then
		printf " $deletedfiles_number""$symbol_deleted"
	fi

	if [ $addedfiles_number -gt 0 ]; then
		printf " $addedfiles_number""$symbol_added"
	fi

	if [ $renamedfiles_number -gt 0 ]; then
		printf " $renamedfiles_number""$symbol_renamed"
	fi

	if [ $untracked_number -gt 0 ]; then
		printf " $untracked_number""$symbol_untracked"
	fi

	if [[ -z "$gitstatus" && "$clean" == "clean" ]]; then
		printf " $symbol_clean"
	fi
}

find_git_commit_diff () {
	if [[ ! -z $(__git_ps1) ]]; then
		# this requires at least git 2.5.0
		currentver=$(git --version | sed -e "s/git version //")
		requiredver="2.5.0"
		if [ "$(printf "$requiredver\n$currentver" | sort -V | head -n1)" == "$currentver" ] && [ "$currentver" != "$requiredver" ]; then
			return
		fi
		commit_diff=$(git for-each-ref --format="%(push:track)" refs/heads)
		commit_diff=${commit_diff//ahead\ /\▲}
		commit_diff=${commit_diff//behind\ /\▼}
		echo $commit_diff
	fi
}


# 'git pull --ff-only' with a short log of the latest changes
ff () {
	local HEADHASH=`git describe --always --abbrev=40`;
	git pull --ff-only $*;
	echo;
	PAGER='cat -B' git log --format="%C(yellow)%h %C(green)%an%C(reset): %s" $HEADHASH.. | sed -nr 's/([^:]+)\:/\1\t/;p';
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
