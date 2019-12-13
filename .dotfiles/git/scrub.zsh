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

  echo "Are you sure you want to delete ${delete_path} and scrub that path from git history?"
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) echo "YES"; break;;
      No ) echo "NO"; return 0;;
    esac
  done

  git filter-branch --force --index-filter \
    "git rm -r --force cached --ignore-unmatch ${delete_path}" \
    --prune-empty --tag-name-filter cat -- --all
}
