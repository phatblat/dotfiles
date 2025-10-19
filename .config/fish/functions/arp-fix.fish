#!/usr/bin/env fish
# arp-fix
# http://krypted.com/mac-security/disable-unicast-arp-cache-validation-in-os-x/
# https://gist.github.com/blimmer/7242676
function arp-fix \
    --description='Disables unicast ARP cache validation'

    if not user_is_admin
        echo "You must be an admin to run this command."
        return 1
    end

    sw_vers -productVersion

    set -l arp_status (list -s (sysctl net.link.ether.inet.arp_unicast_lim))[2]
    echo "net.link.ether.inet.arp_unicast_lim: $arp_status"

    set -l arp_fixed net.link.ether.inet.arp_unicast_lim=0

    if test $arp_status -ne 0
        sudo sysctl -w $arp_fixed
        and set arp_status (list -s (sysctl net.link.ether.inet.arp_unicast_lim))[2]

        if test $arp_status -eq 0
            echo "Fixed ARP issue"
        else
            echo "Something went wrong"
            echo "net.link.ether.inet.arp_unicast_lim: $arp_status"
            return 1
        end
    else
        echo "Runtime ARP status is correct"
    end

    set -l sysctl_file /etc/sysctl.conf
    if not test -e $sysctl_file
        sudo sh -c 'echo '$arp_fixed' >'$sysctl_file
        echo "ARP fix added to "$sysctl_file
    else if not grep --quiet $arp_fixed $sysctl_file
        sudo sh -c 'echo '$arp_fixed' >'$sysctl_file
        echo "ARP fix added to "$sysctl_file
    else
        echo $sysctl_file" already contains the ARP fix."
    end
end
