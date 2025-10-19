#!/usr/bin/env fish
# Configures the firewall to allow incoming connections to the current nginx version.
function firewall_allow_nginx
    firewalladd (brew list nginx | grep 'nginx$')
end
