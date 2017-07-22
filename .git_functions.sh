find_git_dirty () {
  if [[ ! -z $(__git_ps1) && -n $(git status --porcelain) ]]; then printf "\e[41m✗"; fi
}

find_git_commit_diff () {
  if [[ ! -z $(__git_ps1) ]]; then
    commit_diff=$(git for-each-ref --format="%(push:track)" refs/heads)
    commit_diff=${commit_diff//ahead\ /\+}
    commit_diff=${commit_diff//behind\ /\-}
    echo $commit_diff
  fi
}