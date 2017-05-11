# Read nginx error log.
function xerror
    less /usr/local/var/log/nginx/error.log $argv
end
