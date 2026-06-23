# Dependencies:
#   functions: none
#   builtins:  cd print mkdir path exists path type is-empty
#   externals: none

# Quick nav to a dir; creates the dir if not present
export def --env nav [dir?: string] {
    if ($dir == null or ($dir | is-empty)) {
        error make { msg: "Usage: nav dir" }
    }
    if ($dir | path exists) and (($dir | path type) == "dir") {
        cd $dir
    } else {
        mkdir $dir
        cd $dir
    }
}
