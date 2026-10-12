# ltime - Time last command took to complete
export def ltime [] {
    let duration = ($env.CMD_DURATION? | default "")
    if ($duration | is-empty) {
        print "No command duration available"
    } else {
        let secs = (($duration | into float) / 1000)
        print $"($secs)s"
    }
}
