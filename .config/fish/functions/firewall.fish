#!/usr/bin/env fish
function firewall --description='firewall'
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw $argv
end
