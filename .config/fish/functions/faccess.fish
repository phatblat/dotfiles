# Tail the nginx access log.
function faccess
    tail -f /usr/local/var/log/nginx/access.log $argv
end
