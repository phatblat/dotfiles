# 
function finds
      if [[ -z $1 ]]; then
    echo "Missing search term"
    echo 'usage: finds "search string" /base/dir'
    return 1
  fi
  glob="$1"

  base_dir="."
  if [[ -n "$2" ]]; then
    base_dir="$2"
  fi
  if [[ ! -a "${base_dir}" ]]; then
    echo "'${base_dir}' does not exist"
    return 2
  fi

  echo "glob: ${glob}"
  echo "base_dir: ${base_dir}"
  find "${base_dir}" -name "${glob}" -print $argv
end
