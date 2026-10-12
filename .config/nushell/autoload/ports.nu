# ports - Shows open TCP ports
# https://apple.stackexchange.com/questions/117644/how-can-i-list-my-open-network-ports-with-netstat
export def ports [] {
    ^lsof -Pn -i | lines | where $it =~ "LISTEN"
}
