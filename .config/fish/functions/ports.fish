# https://apple.stackexchange.com/questions/117644/how-can-i-list-my-open-network-ports-with-netstat
function ports --description 'Shows open TCP ports'
    lsof -Pn -i | grep LISTEN
end
