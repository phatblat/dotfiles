# 
function o
      if [ -z "$1" ] ; then
    open .
  else
    # -t  Causes the given path to be opened with the default app, as determined via LaunchServices
    open -t "$*"
  fi $argv
end
