#!/usr/bin/env fish
# Flush macOS DNS cache.
function flushdns
    if not user_is_admin
        echo "You must be an admin to run this command."
        return 1
    end

    sudo dscacheutil -flushcache
    and sudo killall -HUP mDNSResponder
    and echo "DNS cache flushed"
end
