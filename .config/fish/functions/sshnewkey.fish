# 
function sshnewkey
      comment="${USER}@${HOST}"
  if (($+1)); then
    comment="$1"
  fi

  ssh-keygen -t rsa -C "${comment}" $argv
end
