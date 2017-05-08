# 
function finddsym
      if [[ $# -ne 1 ]]; then
    echo "Usage: finddsym uuid"
    return 1
  fi

  mdfind "com_apple_xcode_dsym_uuids == <$1>" $argv
end
