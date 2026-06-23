# Dependencies:
#   functions: none
#   builtins:  mkdir cd
#   externals: none

# Create a directory (with -p) and cd into it
export def --env mkcd [...dirs: string] {
    if ($dirs | is-empty) {
        error make { msg: "Usage: mkcd dir [dir2 ...]" }
    }
    mkdir ...$dirs
    # cd into the last non-flag argument (skip if it starts with -)
    let target = ($dirs | last)
    if not ($target | str starts-with "-") {
        cd $target
    }
}
