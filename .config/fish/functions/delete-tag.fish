# 
function delete-tag
      if [[ $# -ne 1 ]]; then
    echo "Usage: delete-tag <tag>"
    return 1
  fi

  # Get the remote for the current branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  local current_remote=$(config branch.${current_branch}.remote)

  git tag --delete $1
  git push ${current_remote} --delete refs/tags/$1 $argv
end
