# Dependencies:
#   functions: none
#   builtins:  path exists print glob is-not-empty ansi is-terminal
#   externals: readlink

# Lists all installed Xcode versions with colorized symlink info
export def xclist [
    --one-per-line (-1)  # Force one entry per line, no colors
] {
    # Match original zsh order: /Applications first, then ~/Applications
    let app_dirs = ["/Applications" $"($env.HOME)/Applications"]
    let xcodes = (
        $app_dirs
        | each { |dir|
            glob $"($dir)/Xcode*.app"
        }
        | flatten
        | where { |p| $p | path exists }
    )

    # Plain output: non-interactive (no tty) or -1 flag — mirrors zsh `[[ ! -t 1 || "$option" == "-1" ]]`
    let is_tty = (is-terminal --stdout)
    if $one_per_line or (not $is_tty) {
        $xcodes | each { |p| print $p }
        return
    }

    # Colorized output showing symlink target
    $xcodes | each { |xcode_path|
        let link_target = (do { ^readlink $xcode_path } | complete | get stdout | str trim)
        if ($link_target | is-not-empty) {
            # Symlinks in magenta
            print $"(ansi magenta)($xcode_path)(ansi reset) -> ($link_target)"
        } else {
            # Directories in blue
            print $"(ansi blue)($xcode_path)(ansi reset)"
        }
    }
    null
}
