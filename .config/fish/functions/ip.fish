#!/usr/bin/env fish
# Show the current IPv4 address
function ip
    en1 | grep 'inet ' | awk '{print $2}'
end
