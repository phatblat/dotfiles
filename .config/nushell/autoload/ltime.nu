# ltime - Time last command took to complete
# Nushell sets $env.CMD_DURATION_MS (a string of milliseconds), not CMD_DURATION.
export def ltime [] {
    let duration = ($env.CMD_DURATION_MS? | default "")
    if ($duration | is-empty) {
        print "No command duration available"
    } else {
        let secs = (($duration | into float) / 1000)
        print $"($secs)s"
    }
}
