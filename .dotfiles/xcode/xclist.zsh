#-------------------------------------------------------------------------------
#
# xcode/xclist.zsh
# Lists all installed copies of Xcode
#
#-------------------------------------------------------------------------------

lj info 'xcode/xclist.zsh'

function xclist {
  local xcode filename

  # echo /Applications/Xcode*.app
  for xcode in /Applications/Xcode*.app; do
    # echo $xcode
    filename=$(basename $xcode)
    echo ${filename%.*};
  done
}
# export -f xclist
# alias xclist="echo /Applications/Xcode*.app"
