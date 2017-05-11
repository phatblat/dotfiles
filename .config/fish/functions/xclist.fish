# 
function xclist
      local xcode filename

  # echo /Applications/Xcode*.app
  for xcode in /Applications/Xcode*.app; do
    # echo $xcode
    filename=$(basename $xcode)
    echo ${filename%.*};
  done $argv
end
