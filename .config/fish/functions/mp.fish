#!/usr/bin/env fish
# Ping mini. Defaults to only 10 pings.
function mp --argument-names count
    if test -z "$count"
        set count 10
    end

    ping -c $count mini
end
