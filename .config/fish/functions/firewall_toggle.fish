# 
function firewall_toggle
    firewall --setglobalstate off && firewall --setglobalstate on $argv
end

