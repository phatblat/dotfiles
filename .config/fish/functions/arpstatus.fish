# Shows the current value of arp_unicast_lim.
function arpstatus
    sysctl -a | grep net.link.ether.inet.arp_unicast_lim
end
