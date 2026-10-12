# console_user - Prints the username of the user logged into the console (GUI)
const is_mac_nu = path self is_mac.nu
source $is_mac_nu
const is_linux_nu = path self is_linux.nu
source $is_linux_nu
const fileowner_nu = path self fileowner.nu
source $fileowner_nu
export def console_user [] {
    if (is_mac) {
        fileowner "/dev/console"
    } else if (is_linux) {
        fileowner "/tmp/.X11-unix/X0"
    } else {
        error make { msg: $"Unknown kernel: ($nu.os-info.name)" }
    }
}
