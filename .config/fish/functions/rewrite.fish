# 
function rewrite
      if [[ $# -ne 3 ]]; then
    echo "Usage: rewrite author|committer old@email new@email"
    return 1
  fi

  if [[ "$1" == "author" ]]; then
    attribute="GIT_AUTHOR_EMAIL"
  elif [[ "$1" == "committer" ]]; then
    attribute="GIT_COMMITTER_EMAIL"
  else
    echo "Usage: rewrite author|committer old@email new@email"
    return 2
  fi

  old_email=$2
  new_email=$3

  filter_command="if [[ \$${attribute} == ${old_email} ]]; then ${attribute}=${new_email}; fi; export ${attribute}"

  git filter-branch -f --env-filter "${filter_command}" $argv
end
