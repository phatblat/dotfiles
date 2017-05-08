# 
function xcswitch
      if [[ $# -ne 1 ]]; then
    echo "Usage: xclinkapp <Version>"
    echo "Version format: 8.3.2"
    return 1
  fi
  local VERSION="$1"
  echo "Activating Xcode Version: ${VERSION}"
  # return 0

  rm -f "/Applications/Xcode.app"
  ln -s "/Applications/Xcode-${VERSION}.app" "/Applications/Xcode.app"
  xcodes
  xcss "/Applications/Xcode-${VERSION}.app"
  xcsp $argv
end
