#!/usr/bin/env fish
# Display HTTP traffic stats using goaccess.
function xtraffic
    goaccess \
        --time-format=%T \
        --date-format=%d/%b/%Y \
        --log-format='%h %^[%d:%t %^] \"%r\" %s %b \"%R\" \"%u\"' \
        -f (brew_home)/var/log/nginx/access.log $argv
end
