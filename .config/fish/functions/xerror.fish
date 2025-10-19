#!/usr/bin/env fish
# Read nginx error log.
function xerror
    less (brew_home)/var/log/nginx/error.log $argv
end
