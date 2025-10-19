#!/usr/bin/env fish
# Read nginx acess log.
function xaccess
    less (brew_home)/var/log/nginx/access.log $argv
end
