# Dependencies:
#   functions: user_is_admin xcss xclist xcsp
#   builtins:  path exists print is-empty path basename
#   externals: ln

# Switch the active version of Xcode by symlinking Xcode-<version>.app to Xcode.app
export def xcswitch [xcode_version: string] {
    if not (user_is_admin) {
        error make { msg: "You must be an admin to run this command." }
    }

    if ($xcode_version | is-empty) {
        error make { msg: "Usage: xcswitch <xcode_version>\nVersion format: 8.3.2" }
    }

    let xcode_path = $"/Applications/Xcode-($xcode_version).app"
    if not ($xcode_path | path exists) {
        error make { msg: $"($xcode_path) does not exist." }
    }

    print $"Activating Xcode Version: ($xcode_version)"

    # Switch the version of Xcode on the system
    xcss $xcode_path

    # Create an Xcode.app symlink so tools that assume Xcode was installed via the
    # MAS use the correct version.
    # -h: if link_name is a symlink, do not follow it
    # -f: unlink existing link before creating
    # -s: symbolic link
    # -v: verbose
    let basename = ($xcode_path | path basename)
    ^ln -hfsv $basename /Applications/Xcode.app

    xclist
    let active = (xcsp | lines | first)
    print $"Activated ($active)"
}
