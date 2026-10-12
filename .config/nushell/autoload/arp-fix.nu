# arp-fix - Disables unicast ARP cache validation
const user_is_admin_nu = path self user_is_admin.nu
source $user_is_admin_nu
export def arp-fix [] {
    if not (user_is_admin) {
        error make { msg: "You must be an admin to run this command." }
    }

    ^sw_vers -productVersion

    let arp_status = (^sysctl net.link.ether.inet.arp_unicast_lim | ^awk '{print $2}' | str trim)
    print $"net.link.ether.inet.arp_unicast_lim: ($arp_status)"

    let arp_fixed = "net.link.ether.inet.arp_unicast_lim=0"

    if ($arp_status | into int) != 0 {
        ^sudo sysctl -w $arp_fixed
        let new_status = (^sysctl net.link.ether.inet.arp_unicast_lim | ^awk '{print $2}' | str trim)

        if ($new_status | into int) == 0 {
            print "Fixed ARP issue"
        } else {
            print "Something went wrong"
            print $"net.link.ether.inet.arp_unicast_lim: ($new_status)"
            error make { msg: "ARP fix failed" }
        }
    } else {
        print "Runtime ARP status is correct"
    }

    let sysctl_file = "/etc/sysctl.conf"
    if not ($sysctl_file | path exists) {
        $"($arp_fixed)\n" | ^sudo tee $sysctl_file
        print $"ARP fix added to ($sysctl_file)"
    } else {
        let match = (do { ^grep -q $arp_fixed $sysctl_file } | complete)
        if $match.exit_code != 0 {
            $"($arp_fixed)\n" | ^sudo tee -a $sysctl_file
            print $"ARP fix added to ($sysctl_file)"
        } else {
            print $"($sysctl_file) already contains the ARP fix."
        }
    }
}
