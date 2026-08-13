# Dependencies:
#   functions: none
#   builtins:  path exists error is-empty
#   externals: realpath

# Recursively search up the directory tree for files matching a pattern
export def findup [pattern: string] {
    if ($pattern | is-empty) {
        error make { msg: "Usage: findup pattern" }
    }

    mut current = (^realpath ".")
    while $current != "/" {
        let target = $"($current)/($pattern)"
        if ($target | path exists) {
            print $target
        }
        $current = ($current | path dirname)
    }
}
