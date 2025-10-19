#!/usr/bin/env fish
# Tail the nginx access log.
function faccess
    tail -f (brew_home)/var/log/nginx/access.log $argv
end
