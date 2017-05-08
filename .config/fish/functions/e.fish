# 
function e
      if [ -z "$1" ] ; then
    edit .
  else
    edit "$*"
  fi $argv
end
