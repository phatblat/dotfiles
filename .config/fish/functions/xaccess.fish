# Read nginx acess log.
function xaccess
    less /usr/local/var/log/nginx/access.log $argv
end
