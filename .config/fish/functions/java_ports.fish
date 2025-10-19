#!/usr/bin/env fish
# java_ports
function java_ports
    lsof -nP | grep TCP | grep java | grep LISTEN
end
