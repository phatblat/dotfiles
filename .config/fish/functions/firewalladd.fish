#!/usr/bin/env fish
# Manage applications that can receive connections through the firewall.
#
# usage: /usr/libexec/ApplicationFirewall/socketfilterfw [-c] [-w] [-d] [-l] [-T] [-U] [-B] [-L] [-a listen or accept] [-p pid to write] [--getglobalstate] [--setglobalstate on | off] [--getblockall] [--setblockall on | off] [--listapps] [--getappblocked <path>] [--blockapp <path>] [--unblockapp <path>] [--add <path>] [--remove <path>] [--getallowsigned] [--setallowsigned] [--setallowsignedapp] [--getstealthmode] [--setstealthmode on | off] [--getloggingmode] [--setloggingmode on | off] [--getloggingopt] [--setloggingopt throttled | brief | detail]
#
# Examples:
#   firewall --add (brew_home)/Cellar/nginx/1.8.0/bin/nginx
#   firewall --unblockapp (brew_home)/Cellar/nginx/1.8.0/bin/nginx
function firewalladd
    echo $argv | read -l app_binary

    if test -z "$app_binary"
        echo "Usage: firewalladd <path>"
        return 1
    end

    if test -e "$app_binary"
        echo "Adding $app_binary to the firewall"
        firewall --add $app_binary
        firewall --unblockapp $app_binary
        firewall_toggle
        return 0
    end

    echo "$app_binary doesn't exist"
    return 2
end
