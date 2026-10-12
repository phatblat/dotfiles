# console_user - Prints the username of the user logged into the console (GUI)
export def console_user [] {
    if (is_mac) {
        fileowner "/dev/console"
    } else if (is_linux) {
        fileowner "/tmp/.X11-unix/X0"
    } else {
        error make { msg: $"Unknown kernel: ($nu.os-info.name)" }
    }
}
