# 
function list-authors
      local all_authors=()
  local format

  if [[ $# -eq 0 ]]; then
    # Email formatting
    format='%an <%ae>'
  elif [[ "$1" == "name" ]]; then
    # Ruby hash
    format='%an'
  elif [[ "$1" == "email" ]]; then
    # Ruby hash
    format='%ae'
  elif [[ "$1" == "ruby" ]]; then
    # Ruby hash
    format='"%an" => "%ae",'
  else
    # Custom format
    format="$1"
  fi

  # Iterate over the hash of all commits
  for commit in $(git rev-list --all)
  do
    all_authors+=("`git --no-pager show -s --format=${format} ${commit}`")
  done

  printf '%s\n' "${all_authors[@]}" | sort | uniq $argv
end
