# Dependencies:
#   functions: is_mac is_linux
#   builtins:  str complete get
#   externals: dsmemberutil groups

# Tests whether the current user is a member of the admin group (macOS or Linux)
export def user_is_admin [] {
    if (is_mac) {
        (^dsmemberutil checkmembership -U $env.USER -G admin | str trim) == "user is a member of the group"
    } else if (is_linux) {
        (do { ^groups } | complete | get stdout | str trim | str contains "adm")
    } else {
        false
    }
}
