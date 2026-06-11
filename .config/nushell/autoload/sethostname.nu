# Dependencies:
#   functions: error-msg user_is_admin
#   builtins:  is-empty
#   externals: sudo scutil defaults

# Set macOS system hostname in all the various places
export def sethostname [new_name: string] {
    if ($new_name | is-empty) {
        error-msg "Usage: sethostname new_name"
        error make { msg: "Usage: sethostname new_name" }
    }

    if not (user_is_admin) {
        error-msg "You must be an admin to run this command."
        error make { msg: "You must be an admin to run this command." }
    }

    ^sudo scutil --set ComputerName $new_name
    ^sudo scutil --set HostName $new_name
    ^sudo scutil --set LocalHostName $new_name
    ^sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string $new_name
}
