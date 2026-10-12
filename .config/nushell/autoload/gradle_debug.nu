# gradle_debug - Toggles Gradle remote debugging on/off
# Usage: gradle_debug [on|off]
export def --env gradle_debug [mode?: string] {
    let heap_space = ($env.GRADLE_HEAP_SPACE? | default "-Xmx1g")
    let turn_on = ($mode == "on") or (($env.GRADLE_OPTS? | default "") | is-empty)
    if $turn_on {
        $env.GRADLE_OPTS = $"($heap_space) -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
        print "Gradle debugging on"
        print $"GRADLE_OPTS: ($env.GRADLE_OPTS)"
    } else {
        $env.GRADLE_OPTS = $heap_space
        print "Gradle debugging off"
    }
}
