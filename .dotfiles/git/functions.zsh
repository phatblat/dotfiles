#-------------------------------------------------------------------------------
#
# git/functions.zsh
# Command-line functions for git
#
#-------------------------------------------------------------------------------

## Delete tag on local and remote
function delete-tag {
  if [[ $# -ne 1 ]]; then
    echo "Usage: delete-tag <tag>"
    return 1
  fi

  # Get the remote for the current branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  local current_remote=$(config branch.${current_branch}.remote)

  git tag --delete $1
  git push ${current_remote} --delete refs/tags/$1
}

## Ignore
function ignore {
  ignores=(
    '.DS_Store'
    '*.xccheckout'
    '*.xcscmblueprint'
    'xcuserdata'
    'Carthage/'
    'Pods/'
    '.rubygems/'
    'bin/'
  )
  for pattern in $ignores; do
    echo "$pattern" >> .gitignore
  done

  git add .gitignore
  git commit -m 'Ignore stuff'
}

# publish
# Publishes the current branch to the given remote
function publish {
  if [[ $# -ne 1 ]]; then
    echo "Usage: publish <remote>"
    return 1
  fi

  branch=$(git rev-parse --abbrev-ref HEAD)

  git push -u $1 $branch
}

# rewrite
# Rewrites history for the current branch, replacing any occurrences of old@email
# with new@email in either the GIT_AUTHOR_EMAIL or GIT_COMMITTER_EMAIL fields
# depending on whether "author" or "committer" is provided as the 1st arg.
function rewrite {
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

  git filter-branch -f --env-filter "${filter_command}"
}

# list-authors
# Extracts a list of contributors from git commit history.
function list-authors {
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

  printf '%s\n' "${all_authors[@]}" | sort | uniq
}
