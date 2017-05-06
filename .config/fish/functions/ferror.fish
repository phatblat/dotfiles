# 
function ferror
    tail -f /usr/local/var/log/nginx/error.log $argv
end

