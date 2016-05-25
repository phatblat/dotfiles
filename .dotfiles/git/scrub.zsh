#-------------------------------------------------------------------------------
#
# git/scrub.zsh
# Function for scrubbing a file from git history.
#
#-------------------------------------------------------------------------------

function scrub {
  if [[ $# -ne 1 ]]; then
    echo "Usage: scrub <path>"
    return 1
  fi

  path=$1
  git filter-branch --force --index-filter \
    "git rm-r --force cached --ignore-unmatch $path" \
    --prune-empty --tag-name-filter cat -- --all
}
