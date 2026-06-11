# Dependencies:
#   functions: path_add
#   builtins:  path exists path join print
#   externals: none

# Set JAVA_HOME and prepend its bin dir to PATH; pass "-" to skip path validation
export def --env jdk_set [
    jdk_path: string   # Path to JDK home, or "-" to skip validation
    quiet?: string     # Any non-empty value suppresses confirmation output
] {
    source /Users/phatblat/.config/nushell/autoload/path_add.nu

    if $jdk_path == "-" {
        print "Skipping jdk_path check"
    } else if not ($jdk_path | path exists) {
        error make { msg: $"Path not found: ($jdk_path)" }
    } else if not (($jdk_path | path join "bin" | path join "java") | path exists) {
        error make { msg: $"No java binary found at path: ($jdk_path)/bin/java" }
    }

    $env.JAVA_HOME = $jdk_path
    path_add $"($env.JAVA_HOME)/bin"

    # Only set CPPFLAGS when the path has no spaces
    if not ($jdk_path | str contains " ") {
        let existing = ($env.CPPFLAGS? | default "")
        $env.CPPFLAGS = $"($existing) -I($jdk_path)/include" | str trim
    }
}
