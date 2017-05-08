# 
function publish
      if [[ $# -ne 1 ]]; then
    echo "Usage: publish <remote>"
    return 1
  fi

  branch=$(git rev-parse --abbrev-ref HEAD)

  git push -u $1 $branch $argv
end
