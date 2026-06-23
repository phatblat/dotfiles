# Dependencies:
#   functions: none
#   builtins:  mkdir path exists
#   externals: none

# Create a set of directories if they don't exist
export def createdirs [...dirs: string] {
    if ($dirs | is-empty) {
        error make { msg: "Usage: createdirs dir1 dir2 ..." }
    }
    for dir in $dirs {
        if not ($dir | path exists) {
            mkdir $dir
        }
    }
}
