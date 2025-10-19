#!/usr/bin/env fish
# Disables and re-enables the firewall.
function firewall_toggle
    firewall --setglobalstate off
    and firewall --setglobalstate on
end
