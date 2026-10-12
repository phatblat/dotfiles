# ips - Show IP addresses
export def ips [] {
    ^ifconfig | ^rg 'inet\s'
}
