#!/usr/bin/env fish
# Prints the port that a local Minecraft server is running on.
# java      32416 phatblat   65u     IPv6 0xcfa44781bf7c86d5        0t0      TCP *:54217 (LISTEN)
function minecraft_server_port --argument-names arg1
    set -l port (string replace '*:' '' (java_ports | awk '{print $9}'))

    if test -n "$port"
        echo "Minecraft server port: "$port
        return
    end

    error "There is no Minecraft server running."
    return 1
end
