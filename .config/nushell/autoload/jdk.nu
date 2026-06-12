# Dependencies:
#   functions: jdk_set jdk_current is_linux
#   builtins:  print ls
#   externals: /usr/libexec/java_home

# Manage JDK selection: list, set, studio, or show current JDK info
export def --env jdk [
    command?: string   # Subcommand: list | set | studio (omit to show current)
    jdk_path?: string  # Path for 'set' subcommand
    quiet?: string     # Non-empty suppresses confirmation output
] {
    source is_linux.nu
    source jdk_set.nu
    source path_add.nu
    source jdk_current.nu

    if (is_linux) {
        ^which java
        ^java -version
        return
    }

    let android_studio = $"($env.HOME)/Applications/Android Studio.app"

    match $command {
        "list" => {
            print "🖥 /usr/libexec/java_home"
            ^/usr/libexec/java_home --verbose

            print ""
            print "🖥 /Library/Java/JavaVirtualMachines"
            ls /Library/Java/JavaVirtualMachines | get name | each { |n| $n | path basename } | to text | print

            if ($android_studio | path exists) {
                print ""
                print "🤖 Android Studio"
                print $"($android_studio)/Contents/jbr/Contents/Home"
            }

            let jabba_path = $"($env.HOME)/.jabba/jdk"
            if ($jabba_path | path exists) {
                print ""
                print $"🐸 Jabba Java candidates in ($jabba_path)"
                ls $jabba_path | get name | each { |n| $n | path basename } | to text | print
            }
        }
        "set" => {
            jdk_set ($jdk_path | default "") $quiet
        }
        "studio" => {
            jdk_set $"($android_studio)/Contents/jbr/Contents/Home" $quiet
        }
        _ => {
            jdk_current
        }
    }
}
