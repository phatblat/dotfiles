# 
function dsyminfo
      if [[ $# -ne 1 ]]; then
    echo "Usage: dsyminfo path/to/dsym"
    return 1
  fi

  dwarfdump -u $1 $argv
end
