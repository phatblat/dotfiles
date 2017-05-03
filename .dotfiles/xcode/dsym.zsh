#-------------------------------------------------------------------------------
#
# xcode/dsym.zsh
# Functions for locating DWARF debug information (dSYM).
#
#-------------------------------------------------------------------------------

lj info 'xcode/dsym.zsh'

alias dsym_uuid="mdls -name com_apple_xcode_dsym_uuids -raw *.dSYM | grep -e \\\" | sed 's/[ |\\\"]//g'"

# https://docs.fabric.io/ios/crashlytics/advanced-setup.html#uploading-dsyms-manually
function finddsym {
  if [[ $# -ne 1 ]]; then
    echo "Usage: finddsym uuid"
    return 1
  fi

  mdfind "com_apple_xcode_dsym_uuids == <$1>"
}

function dsyminfo {
  if [[ $# -ne 1 ]]; then
    echo "Usage: dsyminfo path/to/dsym"
    return 1
  fi

  dwarfdump -u $1
}
