# is_console_user - Tests whether the current user is logged into the console (GUI)
export def is_console_user [] {
    try {
        $env.USER == (^stat -f%Su /dev/console | str trim)
    } catch {
        false
    }
}
