# members - List members of the given group
export def members [group: string] {
    if ($group | is-empty) {
        error make { msg: "Usage: members group" }
    }
    for user in (^dscl . -list /Users | lines) {
        let check = (do { ^dsmemberutil checkmembership -U $user -G $group } | complete)
        if ($check.stdout | str contains "is a member") {
            print $user
        }
    }
}
