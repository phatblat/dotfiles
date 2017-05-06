
# null
function firewall_toggle
    firewall --setglobalstate off && firewall --setglobalstate on
end
