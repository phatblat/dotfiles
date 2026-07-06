# Dependencies:
#   functions: is_mac is_linux
#   builtins:  str complete get split row any
#   externals: dsmemberutil groups

# Tests whether the current user is a member of the admin group (macOS or Linux)
export def user_is_admin [] {
    if (is_mac) {
        let membership = (do { ^dsmemberutil checkmembership -U $env.USER -G admin } | complete)
        if $membership.exit_code == 0 {
            ($membership.stdout | str trim) == "user is a member of the group"
        } else {
            ^groups | str trim | split row " " | any {|group| $group == "admin" }
        }
    } else if (is_linux) {
        ^groups | str trim | split row " " | any {|group| $group == "adm" or $group == "sudo" or $group == "wheel" }
    } else {
        false
    }
}
