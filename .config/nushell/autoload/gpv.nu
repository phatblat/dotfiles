# Dependencies:
#   functions: nav clone pull lg10
#   builtins:  path expand path exists
#   externals: none

# Quick nav to GooglePlatformVersions dir (clone or pull, then cd and show log)
export def --env gpv [] {
    let gpv_dir = ("~/dev/GooglePlatformVersions" | path expand)

    if not ($gpv_dir | path exists) {
        nav ("~/dev" | path expand)
        clone git@github.com:phatblat/GooglePlatformVersions.git
    } else {
        nav $gpv_dir
        pull
    }

    lg10
}
