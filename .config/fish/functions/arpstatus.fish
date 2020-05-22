function arpstatus \
    --description='Shows the current value of arp_unicast_lim.'

    sysctl -a | grep net.link.ether.inet.arp_unicast_lim
end
