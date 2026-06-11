# Dependencies:
#   functions: lg10
#   builtins:  cd path expand path exists
#   externals: git

# Quick nav to ApplePlatformVersions dir (clone or pull, then cd and show log)
export def --env apv [] {
    let apv_dir = ("~/dev/ApplePlatformVersions" | path expand)

    if not ($apv_dir | path exists) {
        cd ("~/dev" | path expand)
        ^git clone git@github.com:phatblat/ApplePlatformVersions.git
    } else {
        cd $apv_dir
        ^git pull
    }

    lg10
}
