# Dependencies:
#   functions: user_is_admin
#   builtins:  print
#   externals: dscacheutil killall

# Flush the macOS DNS cache after verifying the current user is an admin
export def flushdns [] {
    if not (user_is_admin) {
        error make { msg: "You must be an admin to run this command." }
    }
    let result = do { ^sudo dscacheutil -flushcache } | complete
    if $result.exit_code != 0 {
        error make { msg: "dscacheutil failed" }
    }
    ^sudo killall -HUP mDNSResponder
    print "DNS cache flushed"
}
