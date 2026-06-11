# Dependencies:
#   functions: lg10
#   builtins:  cd path expand path exists
#   externals: git

# Quick nav to MicrosoftPlatformVersions dir (clone or pull, then cd and show log)
export def --env mpv [] {
    let mpv_dir = ("~/dev/MicrosoftPlatformVersions" | path expand)

    if not ($mpv_dir | path exists) {
        cd ("~/dev" | path expand)
        ^git clone git@github.com:phatblat/MicrosoftPlatformVersions.git
    } else {
        cd $mpv_dir
        ^git pull
    }

    lg10
}
