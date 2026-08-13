# Dependencies:
#   functions: user_is_admin
#   builtins:  error complete get str trim
#   externals: fdesetup sudo shutdown

# Restart the computer without prompting (requires admin)
export def restart [] {
    # Note: user_is_admin must be sourced before calling this function
    if not (user_is_admin) {
        error make { msg: "You must be an admin to run this command." }
    }

    # Capture fdesetup output regardless of exit status
    let fv_active = (do { ^fdesetup isactive } | complete | get stdout | str trim)
    if $fv_active == "true" {
        ^sudo fdesetup authrestart -verbose
    } else {
        ^sudo shutdown -r now "Rebooting now"
    }
}
