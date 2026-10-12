# arpstatus - Shows the current value of arp_unicast_lim
export def arpstatus [] {
    ^sysctl -a | ^grep net.link.ether.inet.arp_unicast_lim
}
