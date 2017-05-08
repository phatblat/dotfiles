# 
function bashman
      man bash | less -p "^       $1 "; $argv
end
