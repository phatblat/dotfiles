#!/usr/bin/env fish
# Tail the nginx error log.
function ferror
    tail -f (brew_home)/var/log/nginx/error.log $argv
end
