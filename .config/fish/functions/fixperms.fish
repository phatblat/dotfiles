# 
function fixperms
      find "$1" -type f -print -exec chmod 644 {} \;
  find "$1" -type d -print -exec chmod 755 {} \; $argv
end
