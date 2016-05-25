#-------------------------------------------------------------------------------
#
# git/scrub.zsh
# Function for scrubbing a file from git history.
#
#-------------------------------------------------------------------------------

function scrub {
  if [[ $# -ne 1 ]]; then
    echo "Usage: scrub <delete_path>"
    return 1
  fi

  local delete_path=$1
  echo "delete_path: ${delete_path}"

  git filter-branch --force --index-filter \
    "git rm -r --force cached --ignore-unmatch ${delete_path}" \
    --prune-empty --tag-name-filter cat -- --all
}
