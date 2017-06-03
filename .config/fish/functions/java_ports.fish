# java_ports
function java_ports
    lsof -nP | grep TCP | grep java | grep LISTEN
end
